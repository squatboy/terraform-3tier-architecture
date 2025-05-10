## 🇰🇷 README [한국어 보기](#한국어)

# Terraform AWS 3-Tier Architecture Template

This repository provides a Terraform template to deploy a common 3-Tier web architecture on AWS. It's designed to be a starting point for your own projects, allowing for quick setup and customization.

## Architecture Overview

This Terraform project provisions the following 3-Tier architecture on AWS:

```
+-----------------------+       +---------------------------+       +-----------------------+
|      Web Tier         |       |    Application Tier       |       |     Database Tier     |
| (Presentation Layer)  |       |  (Business Logic Layer)   |       |      (Data Layer)     |
+-----------------------+       +---------------------------+       +-----------------------+
|                       |       |                           |       |                       |
| - EC2 Instances       |       | - EC2 Instances           |       | - Amazon RDS          |
|   (Nginx, Apache)     |       |   (Tomcat, Node.js, ...)  |       |   (MySQL, PostgreSQL) |
| - Auto Scaling Group  |       | - Auto Scaling Group      |       |                       |
| - Application Load    +------>|                           |<------+                       |
|   Balancer (ALB)      |       |                           |       |                       |
|                       |       |                           |       |                       |
| **Public Subnets** |          | **Private Subnets**       |       | **Private Subnets**   |
+-----------------------+       +---------------------------+       +-----------------------+
           ^                                  ^                                 ^
           |                                  |                                 |
+-----------------------+       +----------------------------+       +-----------------------+
|       Internet        |       |      Internal Network      |       |   Database Network    |
+-----------------------+       +----------------------------+       +-----------------------+
```

The architecture consists of three main tiers:

1.  **Web Tier (Presentation Layer):**
    *   **Purpose:** Handles incoming user requests and serves static content. Forwards dynamic requests to the Application Tier.
    *   **AWS Services:**
        *   **EC2 Instances:** Run web servers (e.g., Nginx, Apache).
        *   **Auto Scaling Group (ASG):** Ensures high availability and scalability for web servers.
        *   **Application Load Balancer (ALB):** Distributes incoming HTTP/HTTPS traffic across web server instances.
    *   **Network:** Deployed in **Public Subnets** to be accessible from the internet.

2.  **Application Tier (Business Logic Layer):**
    *   **Purpose:** Processes business logic, interacts with the Database Tier, and handles dynamic content generation.
    *   **AWS Services:**
        *   **EC2 Instances:** Run application servers (e.g., Tomcat, Node.js, Python/Django).
        *   **Auto Scaling Group (ASG):** Provides scalability and resilience for application servers.
    *   **Network:** Deployed in **Private Subnets** for enhanced security, accessible only from the Web Tier or other internal resources.

3.  **Database Tier (Data Layer):**
    *   **Purpose:** Stores and manages application data.
    *   **AWS Services:**
        *   **Amazon RDS (Relational Database Service):** Provides a managed relational database (e.g., MySQL, PostgreSQL).
    *   **Network:** Deployed in separate **Private Subnets**, accessible only from the Application Tier.

**Core Networking & Security Components:**

*   **VPC (Virtual Private Cloud):** An isolated network environment for your resources.
*   **Subnets:**
    *   **Public Subnets:** Have a route to the Internet Gateway, used for resources like ALBs and bastion hosts.
    *   **Private Subnets:** Do not have a direct route to the internet. Outbound internet access is provided via a NAT Gateway for tasks like software updates.
*   **Internet Gateway (IGW):** Enables communication between your VPC and the internet.
*   **NAT Gateway:** Allows instances in private subnets to initiate outbound traffic to the internet while preventing inbound traffic.
*   **Route Tables:** Control the flow of traffic within your VPC.
*   **Security Groups:** Act as virtual firewalls for your instances, controlling inbound and outbound traffic at the instance level.

<br>

## Prerequisites

Before you begin, ensure you have the following:

1.  **AWS Account:** An active AWS account.
2.  **AWS CLI:** Installed and configured with your credentials and default region.
    *   Run `aws configure` if you haven't already.
3.  **Terraform:** Installed on your local machine (version >= 1.3.0 recommended).
4.  **Git:** Installed on your local machine.

<br>


## Getting Started

1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/squatboy/terraform-3tier-architecture.git
    cd terraform-3tier-architecture
    ```

2.  **Configure Your Variables:**
    This project uses a `terraform.tfvars` file to manage your specific configuration values.
    *   Rename `terraform.tfvars.example` to `terraform.tfvars`:
        ```bash
        cp terraform.tfvars.example terraform.tfvars
        ```
    *   **Edit `terraform.tfvars`** and provide values for the variables. See the "Key User Inputs" section below for essential variables.

3.  **Initialize Terraform:**
    This command downloads the necessary provider plugins.
    ```bash
    terraform init
    ```

4.  **Plan Your Deployment:**
    This command shows you what resources Terraform will create, modify, or destroy.
    ```bash
    terraform plan
    ```
    Review the plan carefully.

5.  **Apply Your Configuration:**
    This command provisions the AWS resources.
    ```bash
    terraform apply
    ```
    Type `yes` when prompted to confirm.

<br>


## Key User Inputs (Customize in `terraform.tfvars`)

You **must** or **should** customize the following variables in your `terraform.tfvars` file:

*   `aws_region`: (Optional, defaults to "ap-northeast-2") The AWS region where you want to deploy your infrastructure.
    ```terraform
    # aws_region = "us-east-1"
    ```
*   `project_name`: (Optional, defaults to "my3tier") A unique name for your project, used to prefix resource names. This helps in identifying resources and avoiding naming conflicts.
    ```terraform
    # project_name = "my-production-app"
    ```
*   `db_password`: **(Required and Sensitive)** The master password for your RDS database.
    **Important:** Choose a strong, unique password. Do not commit this file with the actual password to a public repository if it's sensitive. Consider using environment variables or a secrets manager for production.
    ```terraform
    db_password = "YourSuperSecurePassword123!"
    ```
*   `ami_id_web`: (Optional) The AMI ID for your Web Tier EC2 instances. If left empty or commented out, the template will attempt to find the latest Amazon Linux 2 AMI for your selected region.
    ```terraform
    # ami_id_web = "ami-xxxxxxxxxxxxxxxxx"
    ```
*   `ami_id_app`: (Optional) The AMI ID for your Application Tier EC2 instances. If left empty or commented out, the template will attempt to find the latest Amazon Linux 2 AMI for your selected region.
    ```terraform
    # ami_id_app = "ami-xxxxxxxxxxxxxxxxx"
    ```

**Other common variables you might want to customize in `terraform.tfvars`:**

*   `vpc_cidr`, `public_subnet_cidrs`, `private_subnet_cidrs`: For custom network addressing.
*   `availability_zones`: To specify which AZs to use. Ensure the number of AZs matches the number of public/private subnets you intend to use per AZ.
*   `web_instance_type`, `app_instance_type`: To change EC2 instance sizes.
*   `db_instance_class`, `db_allocated_storage`, `db_engine`, `db_engine_version`, `db_name`, `db_username`: For RDS database configuration.

Refer to `variables.tf` in the root directory and within each module for a full list of available input variables and their descriptions.

<br>


## Outputs

After a successful `terraform apply`, the following outputs will be displayed:

*   `alb_dns_name`: The DNS name of the Application Load Balancer for accessing the Web Tier.
*   `rds_endpoint`: The connection endpoint for the RDS database instance.
*   `rds_port`: The port for the RDS database instance.
*   `vpc_id`: The ID of the created VPC.
*   And more...

You can also view outputs at any time using:
```bash
terraform output
```

<br>


## Cleaning Up

To destroy all resources created by this Terraform configuration:

```bash
terraform destroy
```
Type `yes` when prompted to confirm. **Be careful, as this will delete all managed infrastructure.**

<br>


## Disclaimer

This template is provided as a starting point. For production environments, consider additional security hardening, monitoring, logging, backup strategies, and cost optimization measures.

---


<br>


## 한국어
# AWS 3티어 아키텍처 Terraform 템플릿

티피컬한 AWS 3티어(3-Tier) 웹 아키텍처를 배포하기 위한 Terraform 템플릿
이 템플릿은 여러분의 프로젝트를 위한 시작점으로 설계되어, 신속한 인프라 설정과 사용자 정의를 가능하게 합니다.

## 아키텍처 개요

이 Terraform 프로젝트는 AWS 상에 다음과 같은 3티어 아키텍처를 프로비저닝합니다:

```
+-----------------------+       +---------------------------+       +-----------------------+
|      Web Tier         |       |    Application Tier       |       |     Database Tier     |
| (Presentation Layer)  |       |  (Business Logic Layer)   |       |      (Data Layer)     |
+-----------------------+       +---------------------------+       +-----------------------+
|                       |       |                           |       |                       |
| - EC2 Instances       |       | - EC2 Instances           |       | - Amazon RDS          |
|   (Nginx, Apache)     |       |   (Tomcat, Node.js, ...)  |       |   (MySQL, PostgreSQL) |
| - Auto Scaling Group  |       | - Auto Scaling Group      |       |                       |
| - Application Load    +------>|                           |<------+                       |
|   Balancer (ALB)      |       |                           |       |                       |
|                       |       |                           |       |                       |
| **Public Subnets** |          | **Private Subnets**       |       | **Private Subnets**   |
+-----------------------+       +---------------------------+       +-----------------------+
           ^                                  ^                                 ^
           |                                  |                                 |
+-----------------------+       +----------------------------+       +-----------------------+
|       Internet        |       |      Internal Network      |       |   Database Network    |
+-----------------------+       +----------------------------+       +-----------------------+
```

이 아키텍처는 세 가지 주요 계층으로 구성됩니다:

1.  **웹 계층 (프레젠테이션 계층):**
    *   **목적:** 사용자의 요청을 받아 처리하고 정적 콘텐츠를 제공합니다. 동적 요청은 애플리케이션 계층으로 전달합니다.
    *   **AWS 서비스:**
        *   **EC2 인스턴스:** 웹 서버(예: Nginx, Apache)를 실행합니다.
        *   **Auto Scaling Group (ASG):** 웹 서버의 고가용성 및 확장성을 보장합니다.
        *   **Application Load Balancer (ALB):** 웹 서버 인스턴스 간에 들어오는 HTTP/HTTPS 트래픽을 분산합니다.
    *   **네트워크:** 인터넷에서 접근 가능하도록 **퍼블릭 서브넷(Public Subnets)** 에 배포됩니다.

2.  **애플리케이션 계층 (비즈니스 로직 계층):**
    *   **목적:** 비즈니스 로직을 처리하고, 데이터베이스 계층과 상호 작용하며, 동적 콘텐츠 생성을 담당합니다.
    *   **AWS 서비스:**
        *   **EC2 인스턴스:** 애플리케이션 서버(예: Tomcat, Node.js, Python/Django)를 실행합니다.
        *   **Auto Scaling Group (ASG):** 애플리케이션 서버의 확장성 및 복원력을 제공합니다.
    *   **네트워크:** 보안 강화를 위해 **프라이빗 서브넷(Private Subnets)** 에 배포되며, 웹 계층이나 다른 내부 리소스에서만 접근 가능합니다.

3.  **데이터베이스 계층 (데이터 계층):**
    *   **목적:** 애플리케이션 데이터를 저장하고 관리합니다.
    *   **AWS 서비스:**
        *   **Amazon RDS (Relational Database Service):** 관리형 관계형 데이터베이스(예: MySQL, PostgreSQL)를 제공합니다.
    *   **네트워크:** 별도의 **프라이빗 서브넷(Private Subnets)** 에 배포되며, 애플리케이션 계층에서만 접근 가능합니다.

**핵심 네트워킹 및 보안 구성 요소:**

*   **VPC (Virtual Private Cloud):** 사용자의 리소스를 위한 격리된 네트워크 환경입니다.
*   **서브넷(Subnets):**
    *   **퍼블릭 서브넷:** 인터넷 게이트웨이로 라우팅 경로가 있어 ALB나 배스천 호스트와 같은 리소스에 사용됩니다.
    *   **프라이빗 서브넷:** 인터넷으로 직접 라우팅 경로가 없습니다. 외부 인터넷으로의 아웃바운드 접근은 소프트웨어 업데이트 등의 작업을 위해 NAT 게이트웨이를 통해 제공됩니다.
*   **인터넷 게이트웨이 (IGW):** VPC와 인터넷 간의 통신을 가능하게 합니다.
*   **NAT 게이트웨이:** 프라이빗 서브넷의 인스턴스가 외부 인터넷으로 아웃바운드 트래픽을 시작할 수 있도록 허용하며, 외부에서의 인바운드 트래픽은 차단합니다.
*   **라우팅 테이블(Route Tables):** VPC 내의 트래픽 흐름을 제어합니다.
*   **보안 그룹(Security Groups):** 인스턴스 수준에서 작동하는 가상 방화벽으로, 인스턴스로 들어오고 나가는 트래픽을 제어합니다.

<br>


## 사전 준비 사항

시작하기 전에 다음 사항을 준비해야 합니다:

1.  **AWS 계정:** 활성화된 AWS 계정.
2.  **AWS CLI:** 로컬 머신에 설치 및 자격 증명(credentials), 기본 리전(region)으로 구성되어 있어야 합니다.
    *   아직 구성하지 않았다면 `aws configure` 명령을 실행.
3.  **Terraform:** 로컬 머신에 설치되어 있어야 합니다 (버전 >= 1.3.0 권장).
4.  **Git:** 로컬 머신에 설치되어 있어야 합니다.

<br>


## 시작하기

1.  **저장소 복제하기:**
    ```bash
    git clone https://github.com/squatboy/terraform-3tier-architecture.git
    cd terraform-3tier-architecture
    ```

2.  **변수 설정하기:**
    이 프로젝트는 `terraform.tfvars` 파일을 사용하여 특정 구성 값을 관리합니다.
    *   `terraform.tfvars.example` 파일의 이름을 `terraform.tfvars`로 변경합니다:
        ```bash
        cp terraform.tfvars.example terraform.tfvars
        ```
    *   **`terraform.tfvars` 파일 수정:** 필요한 변수 값을 입력합니다. 필수 변수에 대한 자세한 내용은 아래 "주요 사용자 입력값" 섹션을 참조.

3.  **Terraform 초기화:**
    이 명령은 필요한 프로바이더 플러그인을 다운로드합니다.
    ```bash
    terraform init
    ```

4.  **배포 계획 검토:**
    이 명령은 Terraform이 생성, 수정 또는 삭제할 리소스를 보여줍니다.
    ```bash
    terraform plan
    ```

5.  **구성 적용하기:**
    이 명령은 AWS 리소스를 프로비저닝합니다.
    ```bash
    terraform apply
    ```
    확인 메시지가 나타나면 `yes`를 입력

<br>


## 주요 사용자 입력값 (`terraform.tfvars`에서 사용자 정의)

`terraform.tfvars` 파일에서 다음 변수들을 **반드시** 또는 **필요에 따라** 사용자 정의해야 합니다:

*   `aws_region`: (선택 사항, 기본값: "ap-northeast-2") 인프라를 배포할 AWS 리전입니다.
    ```terraform
    # aws_region = "us-east-1"
    ```
*   `project_name`: (선택 사항, 기본값: "my3tier") 프로젝트의 고유 이름으로, 리소스 이름의 접두사로 사용됩니다. 리소스를 식별하고 이름 충돌을 방지하는 데 도움이 됩니다.
    ```terraform
    # project_name = "내-프로덕션-앱"
    ```
*   `db_password`: **(필수 및 민감 정보)** RDS 데이터베이스의 마스터 비밀번호입니다.
    **중요:** 강력하고 고유한 비밀번호를 선택하세요! 민감한 정보가 포함된 경우, 이 파일을 실제 비밀번호와 함께 공개 저장소에 커밋하지 마세요. 프로덕션 환경에서는 환경 변수나 시크릿 매니저 사용을 고려하세요!.
    ```terraform
    db_password = "매우안전한나만의비밀번호123!"
    ```
*   `ami_id_web`: (선택 사항) 웹 계층 EC2 인스턴스를 위한 AMI ID입니다. 비워두거나 주석 처리하면, 템플릿은 선택한 리전의 최신 Amazon Linux 2 AMI를 자동으로 찾으려고 시도합니다.
    ```terraform
    # ami_id_web = "ami-xxxxxxxxxxxxxxxxx"
    ```
*   `ami_id_app`: (선택 사항) 애플리케이션 계층 EC2 인스턴스를 위한 AMI ID입니다. 비워두거나 주석 처리하면, 템플릿은 선택한 리전의 최신 Amazon Linux 2 AMI를 자동으로 찾으려고 시도합니다.
    ```terraform
    # ami_id_app = "ami-xxxxxxxxxxxxxxxxx"
    ```

**`terraform.tfvars`에서 사용자 정의할 수 있는 그 외 일반적인 변수들:**

*   `vpc_cidr`, `public_subnet_cidrs`, `private_subnet_cidrs`: 사용자 정의 네트워크 주소 설정을 위함.
*   `availability_zones`: 사용할 가용 영역(AZ)을 지정하기 위함. AZ의 수는 AZ당 사용하려는 퍼블릭/프라이빗 서브넷 수와 일치해야 합니다.
*   `web_instance_type`, `app_instance_type`: EC2 인스턴스 크기를 변경하기 위함.
*   `db_instance_class`, `db_allocated_storage`, `db_engine`, `db_engine_version`, `db_name`, `db_username`: RDS 데이터베이스 구성을 위함.

사용 가능한 모든 입력 변수와 설명은 루트 디렉토리 및 각 모듈 내의 `variables.tf` 파일을 참조

<br>


## 출력값

`terraform apply`가 성공적으로 실행된 후 다음 출력값이 표시됩니다:

*   `alb_dns_name`: 웹 계층에 접근하기 위한 Application Load Balancer의 DNS 이름.
*   `rds_endpoint`: RDS 데이터베이스 인스턴스의 연결 엔드포인트.
*   `rds_port`: RDS 데이터베이스 인스턴스의 포트.
*   `vpc_id`: 생성된 VPC의 ID.
*   그 외 다수...

다음 명령어를 사용하여 언제든지 출력값을 확인할 수 있습니다:
```bash
terraform output
```

<br>


## 리소스 정리하기

이 Terraform 구성으로 생성된 모든 리소스를 삭제하려면 다음 명령을 실행:

```bash
terraform destroy
```
확인 메시지가 나타나면 `yes`를 입력. **주의: 이 작업은 관리되는 모든 인프라를 삭제합니다.**

## 면책 조항

이 템플릿은 시작점으로 제공됩니다. 프로덕션 환경에서는 추가적인 보안 강화, 모니터링, 로깅, 백업 전략 및 비용 최적화 방안을 고려하세요!

---
