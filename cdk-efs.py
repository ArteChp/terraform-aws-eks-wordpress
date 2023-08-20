
import subprocess

from constructs import Construct
from aws_cdk import (
    Stack, Tags, RemovalPolicy, App,
    aws_iam as iam,
)

class EksEfsStack(Stack):

    @staticmethod
    def efs_csi_statement():
        policy_statement_1 = iam.PolicyStatement(
            effect=iam.Effect.ALLOW,
            actions=[
                "elasticfilesystem:DescribeAccessPoints",
                "elasticfilesystem:DescribeFileSystems"
            ],
            resources=['*'],
            conditions={'StringEquals': {"aws:RequestedRegion": "us-west-1"}}
        )

        policy_statement_2 = iam.PolicyStatement(
            effect=iam.Effect.ALLOW,
            actions=[
                "elasticfilesystem:CreateAccessPoint",
                "elasticfilesystem:DeleteAccessPoint"
            ],
            resources=['*'],
            conditions={"StringEquals": {"aws:ResourceTag/efs.csi.aws.com/cluster": "true"}}
        )

        return [policy_statement_1, policy_statement_2]

    def __init__(self, scope: Construct, construct_id: str, oidc_arn, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # EFS CSI SA
        efs_csi_role = iam.Role(
            self, 'EfsCSIRole',
            role_name='eks-efs-csi-sa',
            assumed_by=iam.FederatedPrincipal(
                federated=oidc_arn,
                assume_role_action='sts:AssumeRoleWithWebIdentity',
            )
        )
        for stm in self.efs_csi_statement():
            efs_csi_role.add_to_policy(stm)
        Tags.of(efs_csi_role).add(key='cfn.eks-dev.stack', value='role-stack')

# Construct the stack and pass the oidc_arn
oidc_arn = "arn:aws:iam::204848234318:oidc-provider/oidc.eks.us-west-1.amazonaws.com/id/4ED5BD4A9283A38009C468E591739EF0"
app = App()
stack = EksEfsStack(app, "EksEfsStack", oidc_arn=oidc_arn)
app.synth()

