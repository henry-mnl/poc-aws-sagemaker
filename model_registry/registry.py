"""
SageMaker Model Registry

Provides a high-level interface for:
- Creating and describing a Model Package Group (the registry)
- Registering model versions as Model Packages
- Listing and filtering model versions
- Updating approval status (Approved / Rejected / PendingManualApproval)
- Deploying a model version to a SageMaker real-time endpoint
"""

from __future__ import annotations

import logging
from typing import Any

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Approval status constants
# ---------------------------------------------------------------------------
APPROVED = "Approved"
REJECTED = "Rejected"
PENDING = "PendingManualApproval"


class ModelRegistry:
    """High-level wrapper around the SageMaker Model Registry API."""

    def __init__(
        self,
        model_package_group_name: str,
        region: str | None = None,
        boto_session: boto3.Session | None = None,
    ) -> None:
        """
        Parameters
        ----------
        model_package_group_name:
            Name of the SageMaker Model Package Group that acts as the registry.
        region:
            AWS region name. Falls back to the default region in the environment.
        boto_session:
            Optional pre-configured boto3 Session. When supplied, *region* is
            ignored.
        """
        self._group_name = model_package_group_name
        session = boto_session or boto3.Session(region_name=region)
        self._client = session.client("sagemaker")

    # ------------------------------------------------------------------
    # Model Package Group (registry)
    # ------------------------------------------------------------------

    def create_registry(
        self,
        description: str = "",
        tags: list[dict[str, str]] | None = None,
    ) -> dict[str, Any]:
        """Create the Model Package Group if it does not already exist.

        Parameters
        ----------
        description:
            Human-readable description of this registry.
        tags:
            Optional list of ``{"Key": ..., "Value": ...}`` tag dicts.

        Returns
        -------
        dict
            The raw ``CreateModelPackageGroup`` API response, or an existing-
            group summary dict when the group already exists.
        """
        kwargs: dict[str, Any] = {
            "ModelPackageGroupName": self._group_name,
            "ModelPackageGroupDescription": description,
        }
        if tags:
            kwargs["Tags"] = tags

        try:
            response = self._client.create_model_package_group(**kwargs)
            logger.info(
                "Created Model Package Group '%s': %s",
                self._group_name,
                response["ModelPackageGroupArn"],
            )
            return response
        except ClientError as exc:
            if exc.response["Error"]["Code"] == "ValidationException" and (
                "already exists" in exc.response["Error"]["Message"]
            ):
                logger.info(
                    "Model Package Group '%s' already exists – skipping creation.",
                    self._group_name,
                )
                return self.describe_registry()
            raise

    def describe_registry(self) -> dict[str, Any]:
        """Return metadata for the Model Package Group."""
        return self._client.describe_model_package_group(
            ModelPackageGroupName=self._group_name
        )

    def delete_registry(self) -> None:
        """Delete the Model Package Group (all versions must be deleted first)."""
        self._client.delete_model_package_group(
            ModelPackageGroupName=self._group_name
        )
        logger.info("Deleted Model Package Group '%s'.", self._group_name)

    # ------------------------------------------------------------------
    # Model versions (Model Packages)
    # ------------------------------------------------------------------

    def register_model(
        self,
        inference_spec: dict[str, Any],
        model_metrics: dict[str, Any] | None = None,
        metadata_properties: dict[str, str] | None = None,
        approval_status: str = PENDING,
        description: str = "",
        tags: list[dict[str, str]] | None = None,
    ) -> dict[str, Any]:
        """Register a new model version in the registry.

        Parameters
        ----------
        inference_spec:
            ``InferenceSpecification`` dict describing the container image(s),
            supported content types, and supported instance types.

            Minimal example::

                {
                    "Containers": [{
                        "Image": "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-image:latest",
                        "ModelDataUrl": "s3://my-bucket/model.tar.gz",
                        "Framework": "XGBOOST",
                        "FrameworkVersion": "1.5",
                        "NearestModelName": "xgboost",
                    }],
                    "SupportedTransformInstanceTypes": ["ml.m5.xlarge"],
                    "SupportedRealtimeInferenceInstanceTypes": ["ml.m5.xlarge"],
                    "SupportedContentTypes": ["text/csv"],
                    "SupportedResponseMIMETypes": ["text/csv"],
                }

        model_metrics:
            Optional ``ModelMetrics`` dict (e.g. bias, explainability, quality).
        metadata_properties:
            Optional free-form key/value metadata (``GeneratedBy``, ``ProjectId``, etc.).
        approval_status:
            One of ``"Approved"``, ``"Rejected"``, or ``"PendingManualApproval"``
            (default).
        description:
            Human-readable description for this version.
        tags:
            Optional list of ``{"Key": ..., "Value": ...}`` tag dicts.

        Returns
        -------
        dict
            The raw ``CreateModelPackage`` API response, including
            ``ModelPackageArn``.
        """
        kwargs: dict[str, Any] = {
            "ModelPackageGroupName": self._group_name,
            "InferenceSpecification": inference_spec,
            "ModelApprovalStatus": approval_status,
            "ModelPackageDescription": description,
        }
        if model_metrics:
            kwargs["ModelMetrics"] = model_metrics
        if metadata_properties:
            kwargs["MetadataProperties"] = metadata_properties
        if tags:
            kwargs["Tags"] = tags

        response = self._client.create_model_package(**kwargs)
        logger.info(
            "Registered model version: %s", response["ModelPackageArn"]
        )
        return response

    def list_model_versions(
        self,
        approval_status: str | None = None,
        max_results: int = 100,
        sort_by: str = "CreationTime",
        sort_order: str = "Descending",
    ) -> list[dict[str, Any]]:
        """List model versions (Model Packages) in the registry.

        Parameters
        ----------
        approval_status:
            Optional filter – one of ``"Approved"``, ``"Rejected"``, or
            ``"PendingManualApproval"``.
        max_results:
            Maximum number of versions to return (1–100).
        sort_by:
            Field to sort by. ``"CreationTime"`` or ``"LastModifiedTime"``.
        sort_order:
            ``"Ascending"`` or ``"Descending"``.

        Returns
        -------
        list[dict]
            List of model package summary dicts.
        """
        kwargs: dict[str, Any] = {
            "ModelPackageGroupName": self._group_name,
            "MaxResults": max_results,
            "SortBy": sort_by,
            "SortOrder": sort_order,
        }
        if approval_status:
            kwargs["ModelApprovalStatus"] = approval_status

        versions: list[dict[str, Any]] = []
        while True:
            response = self._client.list_model_packages(**kwargs)
            versions.extend(response.get("ModelPackageSummaryList", []))
            next_token = response.get("NextToken")
            if not next_token:
                break
            kwargs["NextToken"] = next_token

        return versions

    def describe_model_version(self, model_package_arn: str) -> dict[str, Any]:
        """Return full metadata for a single model version.

        Parameters
        ----------
        model_package_arn:
            ARN of the Model Package, e.g. the value of
            ``ModelPackageArn`` returned by :meth:`register_model`.
        """
        return self._client.describe_model_package(
            ModelPackageName=model_package_arn
        )

    def update_approval_status(
        self,
        model_package_arn: str,
        approval_status: str,
        approval_description: str = "",
    ) -> dict[str, Any]:
        """Change the approval status of a model version.

        Parameters
        ----------
        model_package_arn:
            ARN of the Model Package to update.
        approval_status:
            New status: ``"Approved"``, ``"Rejected"``, or
            ``"PendingManualApproval"``.
        approval_description:
            Optional free-text reason for the status change.

        Returns
        -------
        dict
            Raw ``UpdateModelPackage`` API response.
        """
        if approval_status not in (APPROVED, REJECTED, PENDING):
            raise ValueError(
                f"Invalid approval_status '{approval_status}'. "
                f"Must be one of: {APPROVED!r}, {REJECTED!r}, {PENDING!r}."
            )

        response = self._client.update_model_package(
            ModelPackageName=model_package_arn,
            ModelApprovalStatus=approval_status,
            ApprovalDescription=approval_description,
        )
        logger.info(
            "Updated approval status of '%s' to '%s'.",
            model_package_arn,
            approval_status,
        )
        return response

    def delete_model_version(self, model_package_arn: str) -> None:
        """Delete a single model version from the registry."""
        self._client.delete_model_package(ModelPackageName=model_package_arn)
        logger.info("Deleted model package '%s'.", model_package_arn)

    # ------------------------------------------------------------------
    # Deployment helpers
    # ------------------------------------------------------------------

    def deploy(
        self,
        model_package_arn: str,
        endpoint_name: str,
        instance_type: str,
        instance_count: int = 1,
        role_arn: str,
        tags: list[dict[str, str]] | None = None,
    ) -> str:
        """Deploy an approved model version to a real-time endpoint.

        This method:
        1. Creates a ``Model`` resource from the Model Package.
        2. Creates an ``EndpointConfig`` (single-variant, no data capture).
        3. Creates (or updates) the ``Endpoint``.

        Parameters
        ----------
        model_package_arn:
            ARN of the Model Package to deploy.
        endpoint_name:
            Name for the SageMaker endpoint.
        instance_type:
            ML instance type, e.g. ``"ml.m5.xlarge"``.
        instance_count:
            Number of instances behind the endpoint (default 1).
        role_arn:
            IAM execution role ARN. Required for creating the Model resource.
        tags:
            Optional tags applied to all created resources.

        Returns
        -------
        str
            The endpoint ARN.
        """
        tags = tags or []
        model_name = f"{endpoint_name}-model"
        config_name = f"{endpoint_name}-config"

        # 1. Create Model
        self._client.create_model(
            ModelName=model_name,
            PrimaryContainer={"ModelPackageName": model_package_arn},
            ExecutionRoleArn=role_arn,
            Tags=tags,
        )
        logger.info("Created Model resource '%s'.", model_name)

        # 2. Create EndpointConfig
        self._client.create_endpoint_config(
            EndpointConfigName=config_name,
            ProductionVariants=[
                {
                    "VariantName": "AllTraffic",
                    "ModelName": model_name,
                    "InitialInstanceCount": instance_count,
                    "InstanceType": instance_type,
                    "InitialVariantWeight": 1.0,
                }
            ],
            Tags=tags,
        )
        logger.info("Created EndpointConfig '%s'.", config_name)

        # 3. Create or update Endpoint
        try:
            response = self._client.create_endpoint(
                EndpointName=endpoint_name,
                EndpointConfigName=config_name,
                Tags=tags,
            )
            logger.info("Creating endpoint '%s'.", endpoint_name)
        except ClientError as exc:
            if exc.response["Error"]["Code"] == "ValidationException" and (
                "already exists" in exc.response["Error"]["Message"]
            ):
                response = self._client.update_endpoint(
                    EndpointName=endpoint_name,
                    EndpointConfigName=config_name,
                )
                logger.info("Updating existing endpoint '%s'.", endpoint_name)
            else:
                raise

        return response["EndpointArn"]
