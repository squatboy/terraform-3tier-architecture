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
4. Web server proxies to **App EC2**  via private network.
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

시작하기 전에 다음 사항이 준비되어 있는지 확인하십시오:

1. **AWS 계정** – 활성화되어 있고 정상적인 상태여야 합니다.
2. **AWS CLI** – 설치 및 구성 완료 (`aws configure`).
3. **Terraform** ≥ v1.3 (v1.6 이상 권장).
4. **Git** – 로컬에 설치.
5. **검증된 ACM 인증서** – 대상 리전에 있어야 하며, 퍼블릭 **ALB → HTTPS** 리스너에 사용됩니다.


<br>

## 주요 사용자 입력 항목 (terraform.tfvars 파일 편집)

| **변수** | **필수 여부?** | **설명 / 예시** |
| --- | --- | --- |
| aws\_region | 선택 사항 | "ap-northeast-2" |
| project | 선택 사항 | 리소스 이름의 접두사, 예: "my3tier" |
| domain\_name | **필수** | 퍼블릭 DNS 존, 예: "example.com" |
| acm\_certificate\_arn | **필수** | **동일 리전에 있는 ACM 인증서의 ARN** (CloudFront용 us-east-1 인증서는 여기서 유효하지 않습니다) |
| key\_name | **필수** | SSH/SSM 긴급 접근을 위한 EC2 키 페어 이름 |
| db\_username | **필수** | RDS 마스터 사용자 이름 |
| db\_password | **필수 & 민감**| *Secrets Manager 또는 TF\_VAR\_에 저장* |
| vpc\_cidr, public\_subnet\_cidrs, app\_subnet\_cidrs, data\_subnet\_cidrs | 선택 사항 | 사용자 지정 CIDR |
| availability\_zones | 선택 사항 | ["ap-northeast-2a","ap-northeast-2c"] |
| web\_instance\_type, app\_instance\_type | 선택 사항 | t3.micro, t3.small, … |
| db\_instance\_class, db\_allocated\_storage, … | 선택 사항 | RDS 크기 조정 / 엔진 |

전체 목록은 variables.tf를 참조하십시오.

## 출력 항목

| **출력 항목** | **용도** |
| --- | --- |
| alb\_dns | HTTPS Application Load Balancer의 퍼블릭 DNS |
| redis\_primary\_endpoint | Redis (ElastiCache) 주 엔드포인트 |
| rds\_endpoint | RDS 주 엔드포인트 |
| route53\_zone\_id | 도메인의 호스팅 존 ID |
| vpc\_id | VPC 식별자 |
| many more… | terraform output으로 확인 가능 |



## 정리하기

모든 리소스 삭제:

```bash
terraform destroy
```

확인을 위해 yes를 입력하십시오.

> 경고 : 이 작업은 VPC, NAT Gateway, RDS, Redis, Route 53 레코드 등을 제거합니다.


## 면책 조항

이 템플릿은 다음을 결합한 참조 아키텍처입니다:

  - 다중 AZ VPC (Public / App / Data 서브넷)
  - Route 53 + AWS WAF v2 + ALB (TLS 1.2 이상)
  - 웹 / 앱 Auto Scaling Group
  - AZ별 NAT Gateway (패치, S3 로그 업로드, 외부 API를 위한 이그레스)
  - Redis용 ElastiCache (기본 + 복제본, 자동 장애 조치)
  - RDS 다중 AZ (MySQL/PostgreSQL)
  - VPC Gateway ⟶ S3 & DynamoDB, Interface Endpoints ⟶ SSM / CloudWatch

프로덕션 환경 강화를 위해 권장되는 추가 작업:

  - 원격 상태 백엔드 (S3 + DynamoDB 잠금)
  - IAM 최소 권한 & tflint/tfsec을 사용한 CI/CD
  - WAF 사용자 지정 규칙, Shield Advanced (퍼블릭 노출 시)
  - ALB / WAF / Flow / RDS 로그 → S3 + Athena
  - 백업, 암호화 및 비용 최적화 전략

> 자신의 책임 하에 사용하고 조직 정책에 맞게 조정하십시오.


---
