## 🇰🇷 README [한국어 보기](#한국어)


# Terraform AWS 3-Tier Architecture Template

This repository provides a Terraform template to provision a common 3-Tier web architecture on AWS. It's designed to be a starting point for your own projects, allowing for quick setup and customization.

## Architecture Overview

<img width="726" alt="image" src="https://github.com/user-attachments/assets/776f9507-a57e-4b97-a592-b31f0b60c019" />

This Terraform project provisions the following up-to-date 3-Tier web application architecture on AWS.

---

## 1. Web Tier — Global Presentation Layer  
**Purpose:** Deliver static and dynamic content to global users with minimal latency  

| AWS Service                  | Role                                                                                       |
| ---------------------------- | ------------------------------------------------------------------------------------------ |
| **Route 53**                 | Public DNS (e.g. `example.com`) → CloudFront. Global DNS routing and health checks.        |
| **AWS WAF**                  | Web Application Firewall in front of CloudFront (blocks SQLi, XSS, bots, rate limits).     |
| **Amazon CloudFront**        | Accelerates static & dynamic content via global edge locations<br>Origins: S3 and ALB (HTTPS). |
| **AWS Certificate Manager**  | Automatically provisions and renews TLS certificates for CloudFront and ALB.               |
| **Amazon S3**                | Hosts static assets (HTML, CSS, JavaScript, images).                                       |
| **Application Load Balancer**| HTTPS origin for dynamic requests<br>Port 443, SSL termination, cross-AZ load balancing.   |

> **Network:** ALB resides in public subnets (`10.0.1.0/24`, `10.0.10.0/24`)

---

## 2. Application Tier — Business Logic Layer  
**Purpose:** Execute core application logic, read/write cache and database, call external APIs  

| AWS Service               | Role                                                                                 |
| ------------------------- | ------------------------------------------------------------------------------------ |
| **Auto Scaling Group**    | Deploys App servers across two AZs (`10.0.2.0/24`, `10.0.11.0/24`)<br>Auto-scales on CPU & traffic. |
| **Amazon EC2 App Servers**| Hosts business logic and APIs (Tomcat/Node.js).                                      |

> **Network:** Private subnets (`10.0.2.0/24`, `10.0.11.0/24`)<br>  
> **App SG**: allows inbound from ALB SG on ports 80/443

---

## 3. Cache Tier — In-Memory Layer  
**Purpose:** Offload repetitive database operations to reduce latency  

| AWS Service               | Role                          |
| ------------------------- | ----------------------------- |
| **ElastiCache for Redis** | Single-node Redis cache (port 6379) |

> **Network:** same private subnets as the Application Tier

---

## 4. Database Tier — Persistent Data Layer  
**Purpose:** Durable relational data storage  

| AWS Service               | Role                                                                                           |
| ------------------------- | ---------------------------------------------------------------------------------------------- |
| **Amazon RDS (MySQL)**    | **Multi-AZ enabled**:<br>Primary in AZ1 (`10.0.3.0/24`) ↔ Standby in AZ2 (`10.0.12.0/24`)<br>Automatic failover |

> **Network:** Data-Private subnets (`10.0.3.0/24`, `10.0.12.0/24`), no internet route

---

## Core Networking & Security

| Component                    | Description                                                                                                                            |
| ---------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| **VPC 10.0.0.0/16**          | Isolated network containing all resources.                                                                                             |
| **Subnets**                  | • Public: `10.0.1.0/24`, `10.0.10.0/24` (ALB)<br>• App-Private: `10.0.2.0/24`, `10.0.11.0/24`<br>• Data-Private: `10.0.3.0/24`, `10.0.12.0/24` |
| **Internet Gateway**         | Provides internet access for public subnets (ALB).                                                                                     |
| **Route Tables**             | • Public RT → IGW<br>• App-Private RT → no 0.0.0.0/0<br>• Data-Private RT → no 0.0.0.0/0                                                  |
| **Security Groups**          | • **ALB SG**: allows HTTPS (443) from CloudFront IP ranges<br>• **App SG**: allows 80/443 from ALB SG<br>• **Cache SG**: allows 6379 from App SG<br>• **DB SG**: allows 3306 from App SG |

---

## Traffic Flow (High-Level)

1. **Client → Route 53** resolves to your CloudFront distribution.  
2. **Client → CloudFront** traffic is inspected by AWS WAF.  
3. **Static requests** served from CloudFront edge cache (S3).  
4. **Dynamic requests** forwarded: CloudFront → ALB (HTTPS) → EC2 App Servers in private subnets.  
5. App Servers retrieve credentials, check Redis cache → on miss query RDS → cache the result.  
6. Response returns: App → ALB → CloudFront → Client.

---

## High-Availability & Resilience

- **Multi-AZ** App Servers & RDS (automatic failover).  
- **Global edge** via CloudFront for minimal latency.  
- **AWS WAF** + Security Groups for layered security.  
- **ACM** automates TLS certificate management.

---

## Prerequisites

1. **AWS Account** – active and in good standing.  
2. **AWS CLI** – installed & configured (`aws configure`).  
3. **Terraform** ≥ v1.3 (v1.6+ recommended).  
4. **Git** – installed locally.  
5. **ACM Certificate ARN** – for the target region, defined in `terraform.tfvars`.

---

## Key User Inputs (`terraform.tfvars`)

| Variable                  | Required     | Description / Example                                              |
| ------------------------- | ------------ | ------------------------------------------------------------------ |
| `aws_region`              | optional     | e.g. `"ap-northeast-2"`                                            |
| `project`                 | optional     | Prefix for resource names, e.g. `"my3tier"`                        |
| `domain_name`             | **required** | Public DNS zone, e.g. `"example.com"`                              |
| `acm_certificate_arn`     | **required** | ARN of an ACM certificate                                           |
| `key_name`                | **required** | EC2 key-pair name for SSH/SSM break-glass                          |
| `vpc_cidr`                | optional     | VPC CIDR block                                                    |
| `public_subnet_cidrs`     | optional     | Public subnets’ CIDRs                                             |
| `app_subnet_cidrs`        | optional     | App-Private subnets’ CIDRs                                        |
| `data_subnet_cidrs`       | optional     | Data-Private subnets’ CIDRs                                       |
| `availability_zones`      | optional     | e.g. `["ap-northeast-2a","ap-northeast-2c"]`                       |
| `app_instance_type`       | optional     | e.g. `t3.micro`, `t3.small`                                       |
| `db_instance_class`       | optional     | RDS instance class                                                |
| `db_allocated_storage`    | optional     | RDS allocated storage (GB)                                        |

See `variables.tf` for the full list.

---

## Outputs

| Output                       | Description                                   |
| ---------------------------- | --------------------------------------------- |
| `alb_dns`                    | DNS name of the Application Load Balancer    |
| `redis_primary_endpoint`     | ElastiCache Redis primary endpoint            |
| `rds_endpoint`               | RDS primary endpoint                          |
| `route53_zone_id`            | Hosted Zone ID for your domain                |
| `vpc_id`                     | VPC identifier                                |
| _and more…_                  | See `terraform output`                        |

---

## Cleanup
Destroy all resources:
```bash
terraform destroy
```

Type yes to confirm.

> Warning : this removes the VPC, NAT Gateways, RDS, Redis, Route 53 records, etc.

---


<br>


## 한국어
# AWS 3티어 아키텍처 Terraform 템플릿

티피컬한 AWS 3티어(3-Tier) 웹 아키텍처를 프로비저닝하기 위한 Terraform 템플릿
이 템플릿은 여러분의 프로젝트를 위한 시작점으로 설계되어, 신속한 인프라 설정과 사용자 정의를 가능하게 합니다.

## 아키텍처 개요

이 Terraform 프로젝트는 AWS 상에 다음과 같은 3티어 아키텍처를 프로비저닝합니다:

# Terraform 3-Tier Web Architecture (AWS)

이 Terraform 프로젝트는 다음과 같은 최신 3-Tier 웹 애플리케이션 아키텍처를 AWS에 프로비저닝합니다.

---

## 1. Web Tier — Global Presentation Layer  
**목적:** 전 세계 사용자에게 정적·동적 콘텐츠를 최소 지연으로 제공  

| AWS Service                    | 역할                                                                                  |
| ------------------------------ | ------------------------------------------------------------------------------------- |
| **Route 53**                   | Public DNS(`example.com`) → CloudFront 도메인. 글로벌 라우팅 및 헬스체크.              |
| **AWS WAF**                    | CloudFront 앞단에 웹 방화벽 배치<br>SQLi, XSS, 봇 차단, rate limiting 등               |
| **Amazon CloudFront**          | 정적·동적 콘텐츠 모두 글로벌 에지에서 가속<br>Origin: S3(정적) & ALB(동적, HTTPS)       |
| **AWS Certificate Manager**    | CloudFront와 ALB용 TLS 인증서 자동 프로비저닝·갱신                                    |
| **Amazon S3**                  | 정적 자산 호스팅(HTML, CSS, JavaScript, 이미지 등)                                    |
| **Application Load Balancer**  | CloudFront 동적 요청 수신(포트443, SSL 종료)<br>Cross-AZ 로드 밸런싱                   |

> **Network:** ALB는 퍼블릭 서브넷(10.0.1.0/24, 10.0.10.0/24)에 배치

---

## 2. Application Tier — Business Logic Layer  
**목적:** 핵심 비즈니스 로직 실행, 캐시/DB 연동, 외부 API 호출  

| AWS Service                  | 역할                                                                    |
| ---------------------------- | ----------------------------------------------------------------------- |
| **Auto Scaling Group**       | 두 AZ(10.0.2.0/24, 10.0.11.0/24)에 App 서버 배포<br>CPU·트래픽 기반 자동 확장 |
| **EC2 App Servers**          | Tomcat/Node.js 등 애플리케이션 호스팅 및 API 처리                       |

> **Network:** App-Private 서브넷(10.0.2.0/24, 10.0.11.0/24)<br>  
> **App SG**: ALB SG→80/443 인바운드 허용

---

## 3. Cache Tier — In-Memory Layer  
**목적:** 반복적 읽기·쓰기 오프로드로 DB 부담 경감  

| AWS Service               | 역할                        |
| ------------------------- | --------------------------- |
| **ElastiCache for Redis** | 단일 노드 Redis 캐시(포트6379) |

> **Network:** Application Tier와 동일 프라이빗 서브넷

---

## 4. Database Tier — Persistent Data Layer  
**목적:** 내구성 있는 관계형 데이터 스토리지  

| AWS Service                    | 역할                                                                                 |
| ------------------------------ | ------------------------------------------------------------------------------------ |
| **Amazon RDS (MySQL)**         | **Multi-AZ 활성화**<br>AZ1(10.0.3.0/24): Primary ↔ AZ2(10.0.12.0/24): Standby<br>자동 장애 조치 |

> **Network:** Data-Private 서브넷(10.0.3.0/24, 10.0.12.0/24)<br>인터넷 접근 없음

---

## Core Networking & Security

| 구성요소                   | 설명                                                                                                                          |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| **VPC 10.0.0.0/16**        | 모든 리소스를 포함하는 격리 네트워크                                                                                        |
| **Subnets**                | - Public: 10.0.1.0/24, 10.0.10.0/24 (ALB)<br>- App-Private: 10.0.2.0/24, 10.0.11.0/24<br>- Data-Private: 10.0.3.0/24, 10.0.12.0/24 |
| **Internet Gateway**       | 퍼블릭 서브넷(ALB)에 인터넷 연결 제공                                                                                         |
| **Route Tables**           | - Public RT → IGW<br>- App-Private RT → 인터넷 경로 없음<br>- Data-Private RT → 인터넷 경로 없음                                |
| **Security Groups**        | - **ALB SG**: CloudFront IP 범위에서 443 허용<br>- **App SG**: ALB SG→80/443 허용<br>- **Cache SG**: App SG→6379 허용<br>- **DB SG**: App SG→3306 허용 |

---

## Traffic Flow (High-Level)

1. **Client → Route 53** → CloudFront 도메인으로 DNS 해석  
2. **Client → CloudFront** → AWS WAF 검사  
3. **정적 요청** → 에지 캐시(S3)에서 곧바로 응답  
4. **동적 요청** → CloudFront → ALB(HTTPS) → Private EC2 App Server  
5. App Server가 엣지된 **Redis** 캐시 조회 → miss 시 **RDS** 조회 → 결과 캐시  
6. 처리 결과 → ALB → CloudFront → Client

---

## High-Availability & Resilience

- **Multi-AZ** App Servers & RDS (자동 장애 조치)  
- **Global Edge** via CloudFront (최저 지연)  
- **AWS WAF** + Security Groups (다계층 보안)  
- **ACM** 자동 TLS 인증서 관리

---

## Prerequisites

1. **AWS Account** – 활성화된 상태  
2. **AWS CLI** ≥ v2 – 설치 및 `aws configure`  
3. **Terraform** ≥ v1.3 (v1.6+ 권장)  
4. **Git** – 로컬 설치  
5. **ACM Certificate ARN** – 대상 리전의 ACM 인증서 ARN  

---

## Key User Inputs (`terraform.tfvars`)

| 변수 이름                 | 필수 여부     | 설명 / 예시                            |
| ------------------------- | ------------- | -------------------------------------- |
| `aws_region`              | optional      | `"ap-northeast-2"`                     |
| `project`                 | optional      | 리소스 이름 접두사, 예: `"my3tier"`     |
| `domain_name`             | **required**  | 퍼블릭 DNS 존, 예: `"example.com"`     |
| `acm_certificate_arn`     | **required**  | ACM TLS 인증서 ARN                     |
| `key_name`                | **required**  | EC2 SSH KeyPair 이름                   |
| `vpc_cidr`                | optional      | VPC CIDR, 기본 사용 가능               |
| `public_subnet_cidrs`     | optional      | Public 서브넷 CIDRs                    |
| `app_subnet_cidrs`        | optional      | App-Private 서브넷 CIDRs               |
| `data_subnet_cidrs`       | optional      | Data-Private 서브넷 CIDRs              |
| `availability_zones`      | optional      | `["ap-northeast-2a","ap-northeast-2c"]` |
| `app_instance_type`       | optional      | `t3.micro`, `t3.small` 등              |
| `db_instance_class`       | optional      | RDS 인스턴스 클래스                    |
| `db_allocated_storage`    | optional      | RDS 스토리지 크기(GB)                  |

전체 변수 목록은 `variables.tf` 참조.

---

## Outputs

| 출력 이름                   | 설명                                        |
| --------------------------- | ------------------------------------------- |
| `alb_dns`                   | Application Load Balancer 도메인 이름       |
| `redis_primary_endpoint`    | ElastiCache Redis 엔드포인트                |
| `rds_endpoint`              | RDS Primary 엔드포인트                     |
| `route53_zone_id`           | Route 53 Hosted Zone ID                    |
| `vpc_id`                    | VPC ID                                     |
| _and more…_                 | `terraform output` 확인                    |

---

## 정리하기

모든 리소스 삭제:

```bash
terraform destroy
```

확인을 위해 yes를 입력하십시오.

> 경고 : 이 작업은 VPC, NAT Gateway, RDS, Redis, Route 53 레코드 등을 제거합니다.


## 면책 조항

이 템플릿은 아래를 조합한 참조 아키텍처 예시입니다:
-	단일 리전 VPC (Public / App-Private / Data-Private 서브넷)
-	Route 53 + AWS WAF v2 + CloudFront + ALB (TLS 1.2+)
-	Auto Scaling App Servers (멀티 AZ)
-	ElastiCache for Redis (싱글 노드)
-	RDS Multi-AZ (MySQL)

프로덕션 환경 적용 시 다음 추가 작업을 권장합니다:
-	Remote state backend (S3 + DynamoDB lock)
-	IAM least-privilege & CI/CD 보안 검사(tflint, tfsec)
-	ALB / WAF / RDS 로그 수집 → S3 + Athena 분석
-	백업, 암호화 & 비용 최적화 전략

> 자신의 책임 하에 사용하고 조직 정책에 맞게 조정하십시오.


---
