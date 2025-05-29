// file: lib/insecure-stack.ts
import * as cdk  from 'aws-cdk-lib';
import { Construct } from 'constructs';

import * as s3   from 'aws-cdk-lib/aws-s3';
import * as ec2  from 'aws-cdk-lib/aws-ec2';
import * as iam  from 'aws-cdk-lib/aws-iam';
import * as rds  from 'aws-cdk-lib/aws-rds';

export class InsecureStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    /* 1️⃣  Public S3 bucket, all safeguards disabled */
    const bucket = new s3.Bucket(this, 'PublicBucket', {
      bucketName: 'my-public-bucket-001',
      publicReadAccess: true,
      blockPublicAccess: s3.BlockPublicAccess.NONE,   // 🔴 no block-public-access settings
      versioned: false,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
    });

    /* 2️⃣  VPC with a security group open to the world */
    const vpc = new ec2.Vpc(this, 'MyVpc', {
      subnetConfiguration: [
        { name: 'public', subnetType: ec2.SubnetType.PUBLIC },
      ],
      maxAzs: 2,
    });

    const sg = new ec2.SecurityGroup(this, 'OpenSg', {
      vpc,
      description: 'Allow all inbound traffic',
      allowAllOutbound: true,
    });
    sg.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.allTraffic(), 'Wide-open SG');  // 🔴 0.0.0.0/0 ALL

    /* 3️⃣  Wild-card IAM permissions */
    const role = new iam.Role(this, 'OverPermissiveRole', {
      assumedBy: new iam.ServicePrincipal('ec2.amazonaws.com'),
      description: 'Wild-card role for demo',
    });
    role.addManagedPolicy(
      iam.ManagedPolicy.fromAwsManagedPolicyName('AdministratorAccess'), // 🔴 *
    );

    /* 4️⃣  Public, unencrypted RDS instance */
    new rds.DatabaseInstance(this, 'InsecureDb', {
      engine: rds.DatabaseInstanceEngine.postgres({
        version: rds.PostgresEngineVersion.VER_15,
      }),
      vpc,
      publiclyAccessible: true,      // 🔴 internet-facing DB
      storageEncrypted: false,       // 🔴 no encryption at rest
      allocatedStorage: 20,
      credentials: rds.Credentials.fromGeneratedSecret('postgres'),
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });
  }
}
