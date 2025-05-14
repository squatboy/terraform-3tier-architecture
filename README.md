## 🇰🇷 README [한국어 보기](#한국어)


# Terraform AWS 3-Tier Architecture Template

This repository provides a Terraform template to provision a common 3-Tier web architecture on AWS. It's designed to be a starting point for your own projects, allowing for quick setup and customization.

## Architecture Overview

<img width="855" alt="image" src="https://github.com/user-attachments/assets/5afa9421-9899-400a-8604-749b509d9aca" />


This Terraform project provisions the following 3-Tier architecture on AWS:

### 1.  Web Tier — Presentation Layer  
*Purpose :* Accepts user traffic, serves static assets, and proxies dynamic requests downstream.  

| AWS Service                    | Role                                                                                           |
| ------------------------------ | ---------------------------------------------------------------------------------------------- |
| **Route 53**                   | Public‐facing DNS (`example.com → ALB`). Supports health checks & routing policies.            |
| **AWS WAF v2**                 | Web-application firewall attached to the ALB (SQLi, XSS, bot, rate-limit rules).               |
| **Application Load Balancer**  | TLS termination & cross-zone load balancing across both AZs.                                   |
| **EC2 instances (Nginx / Apache)** | Serve static content & act as reverse proxies.                                               |
| **Auto Scaling Group**         | Elastically scales web servers in *public subnets* of **AZ-a** and **AZ-b**.                   |

> **Network :** Hosted in **Public Subnets** (10.0.1.0/24, 10.0.10.0/24) with inbound 80/443 from the ALB only.


### 2.  Application Tier — Business-Logic Layer  
*Purpose :* Executes core logic, calls external APIs, writes/reads cache and DB.  

| AWS Service                    | Role                                                                                           |
| ------------------------------ | ---------------------------------------------------------------------------------------------- |
| **EC2 instances (Node.js / Tomcat / …)** | Runs application containers or processes.                                               |
| **Auto Scaling Group**         | Spans both AZs for HA.                                                                         |
| **NAT Gateway × 2**            | One per AZ; enables outbound traffic (OS patching, S3 log uploads, external API calls).        |

> **Network :** Deployed in **Private Subnets** (10.0.2.0/24, 10.0.11.0/24). Default route → AZ-local NAT GW.


### 3.  Cache Tier — In-Memory Data Layer  
*Purpose :* Reduce latency and offload repetitive reads/writes from the database.  

| AWS Service                    | Role                                                                                           |
| ------------------------------ | ---------------------------------------------------------------------------------------------- |
| **ElastiCache for Redis**      | Multi-AZ replication group – Primary in AZ-a, Replica in AZ-b with automatic fail-over.        |

> **Network :** Same private subnets as the Application Tier; only App-SG allowed on port 6379.


### 4.  Database Tier — Persistent Data Layer  
*Purpose :* Durable storage for relational data.  

| AWS Service                    | Role                                                                                           |
| ------------------------------ | ---------------------------------------------------------------------------------------------- |
| **Amazon RDS (MySQL / PostgreSQL)** | Multi-AZ deployment – Primary in AZ-a, synchronous Standby in AZ-b. Automatic fail-over. |

> **Network :** Dedicated **Data Subnets** (10.0.3.0/24, 10.0.12.0/24) without internet route.


### Core Networking & Security Components

| Component                | Description                                                                                                            |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------------- |
| **VPC 10.0.0.0/16**      | Isolated network containing all resources.                                                                             |
| **Subnets**              | *Public :* 10.0.1.0/24, 10.0.10.0/24  -  *App Private :* 10.0.2.0/24, 10.0.11.0/24  -  *Data Private :* 10.0.3.0/24, 10.0.12.0/24 |
| **Internet Gateway (IGW)** | Enables inbound/outbound internet for public subnets & ALB.                                                          |
| **NAT Gateway × 2**       | Placed in each public subnet for egress from private subnets; resilient to single-AZ failure.                         |
| **Route Tables**          | - Public RT → IGW   - Private-App RT → AZ NATGW   - Private-Data RT (no 0.0.0.0/0).                                    |
| **Security Groups**       | Principle of least privilege (ALB→Web, Web→App, App→Redis/RDS).                                                       |
| **AWS VPC Endpoints (Optional)** | S3 & DynamoDB Gateway endpoints, Interface endpoints for SSM/CloudWatch to reduce NAT traffic & cost.           |
| **CloudWatch / KMS / Kinesis** | Centralised logging, metrics, alarms; encrypted with CMK where applicable.                                       |


### Traffic Flow (high-level)

1. **Client → Route 53** → resolves DNS to ALB.  
2. **Client → ALB** (TLS) → **AWS WAF** inspects request.  
3. ALB forwards to **Web EC2** in the least-loaded AZ.  
4. Web server proxies to **App EC2** via private ALB target group.  
5. App checks **Redis**; on miss, queries **RDS**, then caches result.  
6. Any outbound call (patch, external API, S3 log upload) exits via the AZ-local **NAT Gateway**.  
7. Response propagates back up to the client.


### High-Availability & Resilience Highlights

* **Multi-AZ** Web/App instances, Redis replication, RDS synchronous standby.  
* **Cross-zone ALB** ensures traffic distribution even if one AZ is impaired.  
* **Per-AZ NAT Gateways** eliminate single points of failure for egress.  
* **AWS WAF + SGs** provide layered security per AWS Well-Architected best practices.


<br>

## Prerequisites

Before you begin, ensure you have the following:

1. **AWS Account** – active and in good standing.  
2. **AWS CLI** – installed & configured (`aws configure`).  
3. **Terraform** ≥ v1.3 (v1.6+ recommended).  
4. **Git** – installed locally.  
5. **Validated ACM Certificate** – in the target region for the public **ALB → HTTPS** listener.  

<br>


## Getting Started

1. **Clone the Repository**
```bash
git clone https://github.com/squatboy/terraform-3tier-architecture.git
cd terraform-3tier-architecture
```

2.	**Configure Your Variables**
The project is driven by a terraform.tfvars file.

```bash
cp terraform.tfvars.example terraform.tfvars
```
Edit terraform.tfvars and supply values (see Key User Inputs).

3.	**Initialise Terraform**
```bash
terraform init
```

4.	**Review the Execution Plan**

```bash
terraform plan
```

5.	**Apply**

```bash
terraform apply
```
Type yes to deploy the full multi-AZ stack.

<br>


## Key User Inputs (edit in terraform.tfvars)

| **Variable** | **Required?** | **Description / Example** |
| --- | --- | --- |
| aws_region | optional | "ap-northeast-2" |
| project | optional | Prefix for resource names, e.g. "my3tier" |
| domain_name | **required** | Public DNS zone, e.g. "example.com" |
| acm_certificate_arn | **required** | ARN of an **ACM cert in the same region** (us-east-1 for CloudFront **not** valid here) |
| key_name | **required** | EC2 key-pair name for SSH/SSM break-glass |
| db_username | **required** | RDS master user |
| db_password | **required & sensitive** | *Store in Secrets Manager or TF_VAR_* |
| vpc_cidr, public_subnet_cidrs, app_subnet_cidrs, data_subnet_cidrs | optional | Custom CIDRs |
| availability_zones | optional | ["ap-northeast-2a","ap-northeast-2c"] |
| web_instance_type, app_instance_type | optional | t3.micro, t3.small, … |
| db_instance_class, db_allocated_storage, … | optional | RDS sizing / engine |

See variables.tf for a full catalogue.

## Outputs
| **Output** | **Purpose** |
| --- | --- |
| alb_dns | Public DNS of the HTTPS Application Load Balancer |
| redis_primary_endpoint | Redis (ElastiCache) primary endpoint |
| rds_endpoint | RDS primary endpoint |
| route53_zone_id | Hosted-zone ID for your domain |
| vpc_id | VPC identifier |
| many more… | view with terraform output |

<br>


## Cleaning Up

Destroy all resources:
```bash
terraform destroy
```

Type yes to confirm.

> Warning : this removes the VPC, NAT Gateways, RDS, Redis, Route 53 records, etc.

<br>

## Disclaimer

This template is a reference architecture combining:
-	Multi-AZ VPC (Public / App / Data subnets)
-	Route 53 + AWS WAF v2 + ALB (TLS 1.2+)
-	Web / App Auto Scaling Groups
-	Per-AZ NAT Gateways (egress for patching, S3 log upload, external APIs)
-	ElastiCache for Redis (primary+replica, automatic fail-over)
-	RDS Multi-AZ (MySQL/PostgreSQL)
-	VPC Gateway ⟶ S3 & DynamoDB, Interface Endpoints ⟶ SSM / CloudWatch

Production hardening tasks still recommended:
-	Remote state backend (S3 + DynamoDB lock)
-	IAM least-privilege & CI/CD with tflint/tfsec
-	WAF custom rules, Shield Advanced (if public-facing)
-	ALB / WAF / Flow / RDS logs → S3 + Athena
-	Backup, encryption & cost-optimisation strategies

> Use at your own risk and adapt to organisational policies.

---


<br>


## 한국어
# AWS 3티어 아키텍처 Terraform 템플릿

티피컬한 AWS 3티어(3-Tier) 웹 아키텍처를 프로비저닝하기 위한 Terraform 템플릿
이 템플릿은 여러분의 프로젝트를 위한 시작점으로 설계되어, 신속한 인프라 설정과 사용자 정의를 가능하게 합니다.

## 아키텍처 개요

이 Terraform 프로젝트는 AWS 상에 다음과 같은 3티어 아키텍처를 프로비저닝합니다:

### 1.  웹 계층 — 표현 계층  
*목적 :* 사용자 트래픽을 수신하고, 정적 자산을 제공하며, 동적 요청을 하위 계층으로 프록시합니다.  

| AWS 서비스                    | 역할                                                                                             |
| ---------------------------- | ------------------------------------------------------------------------------------------------ |
| **Route 53**                 | 퍼블릭 DNS (`example.com → ALB`). 상태 확인 및 라우팅 정책 지원.                               |
| **AWS WAF v2**               | ALB에 연결된 웹 애플리케이션 방화벽 (SQLi, XSS, 봇 차단, 속도 제한 규칙 등).                     |
| **Application Load Balancer**| TLS 종료 및 가용 영역 간 로드 밸런싱 수행.                                                       |
| **EC2 인스턴스 (Nginx / Apache)** | 정적 콘텐츠 제공 및 리버스 프록시 역할 수행.                                                |
| **Auto Scaling Group**       | **AZ-a**, **AZ-b**의 *퍼블릭 서브넷*에서 웹 서버를 탄력적으로 확장.                            |

> **네트워크 :** **퍼블릭 서브넷** (10.0.1.0/24, 10.0.10.0/24) 내에 위치하며, ALB로부터의 80/443 포트 인바운드만 허용.


### 2.  애플리케이션 계층 — 비즈니스 로직 계층  
*목적 :* 핵심 비즈니스 로직 실행, 외부 API 호출, 캐시 및 DB 읽기/쓰기 처리.  

| AWS 서비스                          | 역할                                                                                             |
| ---------------------------------- | ------------------------------------------------------------------------------------------------ |
| **EC2 인스턴스 (Node.js / Tomcat / …)** | 애플리케이션 컨테이너 또는 프로세스를 실행.                                                  |
| **Auto Scaling Group**             | 고가용성을 위해 두 개의 AZ에 걸쳐 구성.                                                        |
| **NAT Gateway × 2**                | 가용영역별 1개씩 구성; 아웃바운드 트래픽 (OS 패치, S3 로그 업로드, 외부 API 호출 등)을 허용.    |

> **네트워크 :** **프라이빗 서브넷** (10.0.2.0/24, 10.0.11.0/24)에 배포. 기본 라우트는 AZ 로컬 NAT GW로 설정.


### 3.  캐시 계층 — 인메모리 데이터 계층  
*목적 :* 지연시간을 줄이고 데이터베이스의 반복적인 읽기/쓰기를 오프로드.  

| AWS 서비스                 | 역할                                                                                                 |
| -------------------------- | ------------------------------------------------------------------------------------------------------ |
| **ElastiCache for Redis**  | 다중 AZ 복제 그룹 – 기본 노드는 AZ-a, 복제 노드는 AZ-b. 자동 장애 조치 지원.                        |

> **네트워크 :** 애플리케이션 계층과 동일한 프라이빗 서브넷 내에 위치. 포트 6379은 App-SG만 허용.


### 4.  데이터베이스 계층 — 영속적 데이터 계층  
*목적 :* 관계형 데이터를 위한 영속적인 저장소.  

| AWS 서비스                         | 역할                                                                                                     |
| ---------------------------------- | -------------------------------------------------------------------------------------------------------- |
| **Amazon RDS (MySQL / PostgreSQL)** | 다중 AZ 배포 – 기본 인스턴스는 AZ-a, 동기식 스탠바이 인스턴스는 AZ-b에 존재. 자동 장애 조치 지원.     |

> **네트워크 :** **데이터 전용 서브넷** (10.0.3.0/24, 10.0.12.0/24)에 위치. 인터넷 경로는 없음.


### 핵심 네트워킹 및 보안 구성 요소

| 구성 요소                   | 설명                                                                                                          |
| -------------------------- | ------------------------------------------------------------------------------------------------------------- |
| **VPC 10.0.0.0/16**        | 모든 리소스를 포함하는 격리된 네트워크.                                                                      |
| **서브넷**                 | *퍼블릭 :* 10.0.1.0/24, 10.0.10.0/24  -  *앱 프라이빗 :* 10.0.2.0/24, 10.0.11.0/24  -  *데이터 프라이빗 :* 10.0.3.0/24, 10.0.12.0/24 |
| **Internet Gateway (IGW)** | 퍼블릭 서브넷 및 ALB의 인바운드/아웃바운드 인터넷 연결 지원.                                               |
| **NAT Gateway × 2**        | 퍼블릭 서브넷마다 하나씩 구성되어 프라이빗 서브넷의 egress 트래픽을 담당. 단일 AZ 장애에 대한 복원력 제공. |
| **라우트 테이블**          | - 퍼블릭 RT → IGW   - 프라이빗-앱 RT → AZ NATGW   - 프라이빗-데이터 RT (0.0.0.0/0 없음).                   |
| **보안 그룹**              | 최소 권한 원칙 적용 (ALB→Web, Web→App, App→Redis/RDS).                                                       |
| **AWS VPC 엔드포인트 (선택사항)** | S3 및 DynamoDB용 게이트웨이 엔드포인트, SSM/CloudWatch용 인터페이스 엔드포인트로 NAT 트래픽 및 비용 절감. |
| **CloudWatch / KMS / Kinesis** | 중앙화된 로깅, 지표, 경보 구성; 필요한 경우 CMK로 암호화.                                                  |


### 트래픽 흐름 (상위 레벨)

1. **클라이언트 → Route 53** → DNS를 ALB로 해석.  
2. **클라이언트 → ALB** (TLS) → **AWS WAF**가 요청 검사.  
3. ALB는 **가장 적재가 적은 AZ**의 웹 EC2로 요청 전달.  
4. 웹 서버는 **프라이빗 ALB 대상 그룹**을 통해 App EC2로 프록시 처리.  
5. 애플리케이션은 먼저 **Redis**를 확인하고, 미스 발생 시 **RDS**를 조회한 뒤 결과를 캐시.  
6. 아웃바운드 트래픽 (패치, 외부 API, S3 로그 업로드 등)은 해당 AZ의 **NAT Gateway**를 통해 나감.  
7. 응답은 클라이언트로 역방향 전파됨.

---

### 고가용성 및 복원력 하이라이트

* **다중 AZ** 웹/앱 인스턴스, Redis 복제, RDS 동기식 스탠바이 구성.  
* **크로스존 ALB**로 AZ 장애 시에도 트래픽 분산 보장.  
* **AZ별 NAT 게이트웨이**로 egress 단일 장애 지점 제거.  
* **AWS WAF + 보안 그룹**을 통한 AWS Well-Architected 보안 모범 사례 준수.
  
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
