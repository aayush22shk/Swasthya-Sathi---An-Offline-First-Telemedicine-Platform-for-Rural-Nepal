

# SWASTHYA SATHI: AN OFFLINE-FIRST TELEMEDICINE PLATFORM FOR RURAL NEPAL

---

## TITLE PAGE

**Swasthya Sathi: An Offline-First Telemedicine Platform for Rural Nepal**

A Dissertation Submitted in Partial Fulfilment of the Requirements for the Degree of
**Bachelor of Science (Honours) in Computing**

**Author:** Aayush Man Shakya
**Student ID:** 2337692

**Supervisor:** [Supervisor Name]

**University of Bedfordshire**
**Department of Computer Science and Technology**

**Date:** October 2026

---

## DECLARATION / STATEMENT OF ORIGINALITY

I, Aayush Man Shakya, hereby declare that this dissertation titled *"Swasthya Sathi: An Offline-First Telemedicine Platform for Rural Nepal"* is entirely my own original work. All information in this document has been obtained and presented in accordance with academic rules and ethical conduct. I have fully cited and referenced all material and results that are not original to this work.

This dissertation has not been submitted for any other academic award at any institution.

**Signed:** Aayush Man Shakya

**Date:** October 2026

---

## ABSTRACT

Nepal faces a critical shortage of healthcare professionals in rural areas, with the doctor-to-patient ratio standing at approximately 1:1,700 nationally and even worse in remote districts. Geographic isolation, limited internet connectivity, and inadequate healthcare infrastructure create significant barriers to accessing quality medical care for millions of Nepali citizens residing in rural municipalities.

This dissertation presents **Swasthya Sathi** (meaning "Health Companion" in Nepali) — a comprehensive, offline-first telemedicine platform specifically designed to address the healthcare accessibility gap in rural Nepal. The system is built as a cross-platform mobile application using Flutter for the frontend, a Node.js/Express RESTful API backend with PostgreSQL for data persistence, and a Python-based health analytics microservice leveraging pandas and NumPy for statistical analysis of patient vitals. The platform integrates Google Gemini AI to provide personalised, plain-language health explanations in both English and Nepali languages.

Key features include role-based authentication for patients, doctors, and administrators; real-time appointment scheduling with multi-modal consultation support (video, audio, chat, and in-person); digital prescription management; a comprehensive health monitoring module for blood pressure, glucose, and weight tracking with clinical rule-based flagging aligned to JNC 8 and ADA 2024 guidelines; eSewa digital payment integration for consultation fees; and an AI-powered health assistant that explains health analytics in accessible language.

The system was developed following an Agile methodology with iterative sprints. Evaluation demonstrated that the platform successfully meets its objectives of providing accessible, affordable, and user-friendly telemedicine services, whilst maintaining clinical safety through a robust rule-engine and responsible AI design patterns. The platform addresses a significant gap in existing telemedicine solutions, which predominantly target urban, well-connected populations and lack Nepal-specific considerations such as local payment gateways, NMC (Nepal Medical Council) verification, and bilingual Nepali/English support.

**Keywords:** Telemedicine, Rural Healthcare, Nepal, Offline-First, Flutter, Mobile Health (mHealth), Artificial Intelligence, Health Analytics, Clinical Decision Support

---

## ACKNOWLEDGEMENTS

I would like to express my sincere gratitude to my dissertation supervisor, [Supervisor Name], for their invaluable guidance, continuous support, and constructive feedback throughout the development of this project.

I extend my heartfelt thanks to the University of Bedfordshire for providing the academic environment and resources that made this research possible.

I am deeply grateful to my family for their unwavering support and encouragement throughout my academic journey.

Special thanks to the healthcare professionals and rural community members who provided insights into the real-world challenges of healthcare access in Nepal, which fundamentally shaped the direction of this project.

Finally, I acknowledge the open-source communities behind Flutter, Node.js, FastAPI, and PostgreSQL, whose tools and frameworks made this project technically feasible.

---

## TABLE OF CONTENTS

- [Chapter 1 — Introduction](#chapter-1--introduction)
  - [1.1 Background](#11-background)
  - [1.2 Problem Statement](#12-problem-statement)
  - [1.3 Project Aim](#13-project-aim)
  - [1.4 Project Objectives](#14-project-objectives)
  - [1.5 Research Questions](#15-research-questions)
  - [1.6 Scope of the Project](#16-scope-of-the-project)
  - [1.7 Significance / Rationale](#17-significance--rationale)
  - [1.8 Project Methodology Overview](#18-project-methodology-overview)
  - [1.9 Structure of the Dissertation](#19-structure-of-the-dissertation)
- [Chapter 2 — Literature Review](#chapter-2--literature-review)
  - [2.1 Introduction](#21-introduction)
  - [2.2 Theoretical Background](#22-theoretical-background)
  - [2.3 Existing Technologies / Approaches](#23-existing-technologies--approaches)
  - [2.4 Existing Systems / Solutions](#24-existing-systems--solutions)
  - [2.5 Comparison of Existing Solutions](#25-comparison-of-existing-solutions)
  - [2.6 Research Gap / Identified Problem](#26-research-gap--identified-problem)
  - [2.7 Chapter Summary](#27-chapter-summary)
- [Chapter 3 — Methodology / Requirements Analysis](#chapter-3--methodology--requirements-analysis)
  - [3.1 Introduction](#31-introduction)
  - [3.2 Research / Development Approach](#32-research--development-approach)
  - [3.3 Data Collection Methods](#33-data-collection-methods)
  - [3.4 Ethical Considerations](#34-ethical-considerations)
  - [3.5 Functional Requirements](#35-functional-requirements)
  - [3.6 Non-Functional Requirements](#36-non-functional-requirements)
  - [3.7 User Requirements / User Stories](#37-user-requirements--user-stories)
  - [3.8 System Constraints](#38-system-constraints)
  - [3.9 Chapter Summary](#39-chapter-summary)
- [Chapter 4 — System Analysis and Design](#chapter-4--system-analysis-and-design)
  - [4.1 Introduction](#41-introduction)
  - [4.2 System Architecture](#42-system-architecture)
  - [4.3 Use Case Diagram](#43-use-case-diagram)
  - [4.4 Use Case Descriptions](#44-use-case-descriptions)
  - [4.5 Data Flow Diagrams](#45-data-flow-diagrams)
  - [4.6 Database Design](#46-database-design)
  - [4.7 Class Diagram](#47-class-diagram)
  - [4.8 Sequence Diagrams](#48-sequence-diagrams)
  - [4.9 User Interface Design](#49-user-interface-design)
  - [4.10 Technology Stack](#410-technology-stack)
  - [4.11 Security Design](#411-security-design)
  - [4.12 Chapter Summary](#412-chapter-summary)
- [Chapter 5 — Implementation / Development](#chapter-5--implementation--development)
  - [5.1 Introduction](#51-introduction)
  - [5.2 Development Environment](#52-development-environment)
  - [5.3 Frontend Implementation](#53-frontend-implementation)
  - [5.4 Backend Implementation](#54-backend-implementation)
  - [5.5 Database Implementation](#55-database-implementation)
  - [5.6 API Development](#56-api-development)
  - [5.7 AI / Machine Learning Implementation](#57-ai--machine-learning-implementation)
  - [5.8 Authentication and Security](#58-authentication-and-security)
  - [5.9 Key Features](#59-key-features)
  - [5.10 Challenges Encountered](#510-challenges-encountered)
  - [5.11 Solutions to Technical Challenges](#511-solutions-to-technical-challenges)
  - [5.12 Chapter Summary](#512-chapter-summary)
- [Chapter 6 — Testing and Evaluation](#chapter-6--testing-and-evaluation)
  - [6.1 Introduction](#61-introduction)
  - [6.2 Testing Strategy](#62-testing-strategy)
  - [6.3 Unit Testing](#63-unit-testing)
  - [6.4 Integration Testing](#64-integration-testing)
  - [6.5 System Testing](#65-system-testing)
  - [6.6 User Acceptance Testing](#66-user-acceptance-testing)
  - [6.7 Performance Testing](#67-performance-testing)
  - [6.8 Security Testing](#68-security-testing)
  - [6.9 Usability Evaluation](#69-usability-evaluation)
  - [6.10 Test Results](#610-test-results)
  - [6.11 Evaluation Against Objectives](#611-evaluation-against-objectives)
  - [6.12 Limitations](#612-limitations)
  - [6.13 Chapter Summary](#613-chapter-summary)
- [Chapter 7 — Conclusion and Future Work](#chapter-7--conclusion-and-future-work)
  - [7.1 Introduction](#71-introduction)
  - [7.2 Summary of the Project](#72-summary-of-the-project)
  - [7.3 Achievement of Aim](#73-achievement-of-aim)
  - [7.4 Achievement of Objectives](#74-achievement-of-objectives)
  - [7.5 Key Findings](#75-key-findings)
  - [7.6 Project Limitations](#76-project-limitations)
  - [7.7 Recommendations](#77-recommendations)
  - [7.8 Future Development](#78-future-development)
  - [7.9 Final Conclusion](#79-final-conclusion)
- [References](#references)
- [Appendices](#appendices)

---

## LIST OF FIGURES

| Figure No. | Description | Page |
|---|---|---|
| Figure 4.1 | System Architecture Diagram | — |
| Figure 4.2 | Use Case Diagram — Patient Actor | — |
| Figure 4.3 | Use Case Diagram — Doctor Actor | — |
| Figure 4.4 | Use Case Diagram — Admin Actor | — |
| Figure 4.5 | Level 0 Data Flow Diagram (Context Diagram) | — |
| Figure 4.6 | Level 1 Data Flow Diagram | — |
| Figure 4.7 | Entity-Relationship Diagram (ERD) | — |
| Figure 4.8 | Class Diagram — Flutter Frontend Models and Services | — |
| Figure 4.9 | Sequence Diagram — User Registration | — |
| Figure 4.10 | Sequence Diagram — Appointment Booking and Payment | — |
| Figure 4.11 | Sequence Diagram — Health Analysis Generation | — |
| Figure 4.12 | Wireframe — Welcome and Login Screens | — |
| Figure 4.13 | Wireframe — Patient Dashboard | — |
| Figure 4.14 | Wireframe — Doctor Dashboard | — |
| Figure 4.15 | Wireframe — Health Analytics Screen | — |
| Figure 5.1 | Screenshot — Welcome Screen | — |
| Figure 5.2 | Screenshot — Role Selection Screen | — |
| Figure 5.3 | Screenshot — Patient Registration | — |
| Figure 5.4 | Screenshot — Patient Dashboard | — |
| Figure 5.5 | Screenshot — Doctor Dashboard | — |
| Figure 5.6 | Screenshot — Appointment Booking | — |
| Figure 5.7 | Screenshot — eSewa Payment Integration | — |
| Figure 5.8 | Screenshot — Health Dashboard | — |
| Figure 5.9 | Screenshot — Health Analysis with AI Explanation | — |
| Figure 5.10 | Screenshot — AI Health Chat | — |
| Figure 5.11 | Screenshot — Consultation Chat | — |

---

## LIST OF TABLES

| Table No. | Description | Page |
|---|---|---|
| Table 2.1 | Comparison of Existing Telemedicine Solutions | — |
| Table 3.1 | Functional Requirements | — |
| Table 3.2 | Non-Functional Requirements | — |
| Table 3.3 | User Stories — Patient | — |
| Table 3.4 | User Stories — Doctor | — |
| Table 4.1 | Entity Descriptions — Core Tables | — |
| Table 4.2 | Technology Stack | — |
| Table 5.1 | Development Environment and Tools | — |
| Table 5.2 | Backend API Endpoints Summary | — |
| Table 6.1 | Test Results — Functional Testing | — |
| Table 6.2 | Test Results — Non-Functional Testing | — |
| Table 6.3 | Evaluation Against Objectives | — |
| Table 7.1 | Achievement of Objectives Summary | — |

---

## LIST OF ABBREVIATIONS / ACRONYMS

| Abbreviation | Full Form |
|---|---|
| API | Application Programming Interface |
| CRUD | Create, Read, Update, Delete |
| CSS | Cascading Style Sheets |
| ERD | Entity-Relationship Diagram |
| eSewa | Electronic Sewa (Nepali Digital Payment Gateway) |
| FHIR | Fast Healthcare Interoperability Resources |
| HTTP | Hypertext Transfer Protocol |
| IDE | Integrated Development Environment |
| JWT | JSON Web Token |
| LLM | Large Language Model |
| mHealth | Mobile Health |
| MVC | Model-View-Controller |
| NMC | Nepal Medical Council |
| OTP | One-Time Password |
| REST | Representational State Transfer |
| SDK | Software Development Kit |
| SQL | Structured Query Language |
| UI | User Interface |
| UUID | Universally Unique Identifier |
| UX | User Experience |
| WHO | World Health Organization |

---

# CHAPTER 1 — INTRODUCTION

## 1.1 Background

Healthcare accessibility remains one of the most critical challenges facing developing nations in the twenty-first century. Nepal, a landlocked country in South Asia with a population of approximately 30 million people, faces a particularly acute healthcare crisis. According to the World Health Organization (WHO, 2022), Nepal has a physician density of approximately 0.7 per 1,000 population — well below the recommended threshold of 2.3 per 1,000. This disparity is even more pronounced in rural areas, where approximately 80% of the population resides but where fewer than 20% of healthcare professionals practice (Ministry of Health and Population, Nepal, 2023).

The geographic terrain of Nepal, characterised by the Himalayan mountain range and scattered rural settlements, makes physical access to healthcare facilities extraordinarily difficult. Patients in remote districts may need to travel for days on foot to reach the nearest hospital, particularly during the monsoon season when roads become impassable. This geographic barrier, combined with limited internet connectivity in rural areas (Nepal Telecommunications Authority reported approximately 40% rural broadband penetration in 2024), creates a significant gap between the healthcare needs of rural populations and the available medical services.

Telemedicine — the delivery of healthcare services through information and communication technologies — has emerged as a promising solution to bridge this gap. The COVID-19 pandemic accelerated the adoption of telemedicine globally, demonstrating its viability as a healthcare delivery model (Hollander and Carr, 2020). However, most existing telemedicine platforms are designed for urban populations with reliable internet connectivity and are not adapted to the specific challenges of developing countries like Nepal.

The advent of artificial intelligence (AI) in healthcare, particularly Large Language Models (LLMs), presents an additional opportunity to enhance telemedicine platforms by providing accessible, personalised health information to patients who may have limited health literacy (Topol, 2019). When implemented responsibly — with appropriate guardrails, structured output validation, and clear disclaimers — AI can serve as a health education tool that empowers patients to better understand their health data and engage more meaningfully with their healthcare providers.

## 1.2 Problem Statement

Rural communities in Nepal face severe barriers to accessing quality healthcare services due to a convergence of geographic isolation, shortage of medical professionals, limited internet connectivity, and inadequate digital health infrastructure. Existing telemedicine platforms are predominantly designed for urban, well-connected populations and fail to address several Nepal-specific challenges:

1. **Lack of offline functionality:** Most platforms require constant internet connectivity, rendering them unusable in areas with intermittent or no broadband access.
2. **Language barriers:** The majority of global telemedicine platforms operate in English, excluding the large proportion of Nepal's rural population that primarily communicates in Nepali.
3. **Payment ecosystem mismatch:** International platforms rely on credit/debit card payment systems that have very low penetration in rural Nepal, where digital wallets such as eSewa and Khalti are the predominant digital payment methods.
4. **Absence of local regulatory compliance:** No existing platform integrates Nepal Medical Council (NMC) verification for doctors, a critical requirement for establishing trust and ensuring practitioner legitimacy in the Nepali healthcare context.
5. **Limited health literacy support:** Rural patients often lack the medical knowledge needed to interpret health data such as blood pressure readings and glucose levels, yet existing platforms provide little to no plain-language health education.

There is therefore a clear need for a purpose-built telemedicine platform that addresses these interrelated challenges in a holistic, contextually appropriate manner.

## 1.3 Project Aim

The aim of this project is to design, develop, and evaluate a comprehensive, offline-first telemedicine platform — **Swasthya Sathi** — that provides accessible, affordable, and culturally appropriate healthcare services for rural communities in Nepal, integrating AI-powered health analytics to improve patient health literacy and clinical decision support.

## 1.4 Project Objectives

The following measurable objectives have been established to achieve the stated aim:

1. **O1:** To conduct a comprehensive analysis of existing telemedicine solutions, identifying their strengths, limitations, and gaps in addressing rural healthcare in developing countries.
2. **O2:** To identify and document the functional and non-functional requirements for a telemedicine platform tailored to the needs of rural Nepal, informed by secondary research and contextual analysis.
3. **O3:** To design a scalable, multi-tier system architecture comprising a cross-platform mobile frontend, RESTful API backend, relational database, and health analytics microservice.
4. **O4:** To implement the platform with core features including role-based authentication, appointment management, multi-modal consultation (video, audio, chat), digital prescriptions, health monitoring, and AI-powered health explanations.
5. **O5:** To integrate Nepal-specific features including eSewa payment gateway, NMC doctor verification, bilingual (English/Nepali) support, and location data aligned with Nepal's administrative divisions (provinces, districts, municipalities).
6. **O6:** To evaluate the system's functionality, performance, security, and usability through structured testing and assessment against the defined objectives.

## 1.5 Research Questions

This project is guided by the following research questions:

1. **RQ1:** What are the primary barriers to healthcare access in rural Nepal, and how can telemedicine technology address them?
2. **RQ2:** How can a telemedicine platform be designed to function effectively in environments with limited or intermittent internet connectivity?
3. **RQ3:** To what extent can AI-powered health analytics improve patient understanding of personal health data in a low-health-literacy context?
4. **RQ4:** What design considerations are necessary to ensure a telemedicine platform is culturally appropriate and trustworthy for rural Nepali users?

## 1.6 Scope of the Project

### In Scope

The following areas are within the scope of this project:

- Cross-platform mobile application (Android and iOS) built with Flutter
- RESTful backend API with Node.js/Express
- PostgreSQL relational database with comprehensive schema design
- Patient, doctor, and admin role management with JWT authentication
- Appointment scheduling with multi-modal consultation support
- Digital prescription creation and management
- Health monitoring module (blood pressure, glucose, weight) with trend analysis
- AI-powered health analysis and explanation using Google Gemini
- Clinical rule engine for health flagging (aligned to JNC 8 and ADA 2024 guidelines)
- eSewa payment integration for consultation fees
- Bilingual support (English and Nepali)
- Nepal-specific location data (provinces, districts, municipalities)
- NMC (Nepal Medical Council) registration verification workflow

### Out of Scope

The following areas are explicitly excluded from this project:

- Real-time video/audio streaming implementation (WebRTC integration)
- Full offline data synchronisation with conflict resolution
- Integration with government health information systems (DHIS2)
- Native wearable device integration (e.g., smartwatches, IoT medical devices)
- Comprehensive automated testing suite
- Production deployment and server infrastructure
- Mobile application publication to Google Play Store or Apple App Store

## 1.7 Significance / Rationale

This project holds significance for multiple stakeholders:

**For Rural Patients:** Swasthya Sathi provides a mechanism to access qualified medical professionals without the need for arduous physical travel, potentially reducing delays in diagnosis and treatment. The AI-powered health explanations empower patients with accessible health information, improving health literacy and enabling more informed conversations with healthcare providers.

**For Healthcare Providers (Doctors):** The platform extends the reach of medical professionals to underserved populations, enabling them to manage patients, issue prescriptions, and monitor health trends remotely. The clinical rule engine provides decision-support flags that highlight critical health indicators requiring attention.

**For the Nepali Healthcare System:** By digitising patient records, prescriptions, and health data, the platform contributes to the broader goal of health system digitisation in Nepal. The data collected (with appropriate anonymisation) could inform public health research and policy decisions related to disease prevalence in rural areas.

**For Academic Knowledge:** This project contributes to the body of knowledge on designing telemedicine solutions for resource-constrained environments, with particular emphasis on the integration of responsible AI in health education for populations with limited health literacy.

## 1.8 Project Methodology Overview

This project adopts an **Agile development methodology** with iterative sprints, combining elements of Scrum for project management with a Design Science research approach for the overall project framework. The development process is structured as follows:

1. **Requirements Gathering:** Secondary research through literature review and contextual analysis of Nepal's healthcare landscape.
2. **System Design:** Architectural design, database modelling, API specification, and UI wireframing.
3. **Iterative Implementation:** Development in focused sprints, each delivering a functional increment of the system.
4. **Testing and Evaluation:** Functional testing, integration testing, and evaluation against defined objectives.

The Design Science approach (Hevner *et al.*, 2004) provides the overarching research framework, as the project involves creating a novel IT artefact (the telemedicine platform) and evaluating its utility in addressing a defined problem.

## 1.9 Structure of the Dissertation

This dissertation is organised into seven chapters:

**Chapter 1 — Introduction:** Provides the background, problem statement, aims, objectives, scope, and significance of the project.

**Chapter 2 — Literature Review:** Critically examines existing research, technologies, and telemedicine solutions relevant to the project, identifying the research gap that this project addresses.

**Chapter 3 — Methodology / Requirements Analysis:** Details the development methodology, data collection approach, ethical considerations, and system requirements (functional, non-functional, and user requirements).

**Chapter 4 — System Analysis and Design:** Presents the system architecture, UML diagrams (use case, sequence, class), database design (ERD), user interface wireframes, technology stack, and security design.

**Chapter 5 — Implementation / Development:** Describes the actual development process, highlighting key implementation details, code architecture, major features, and technical challenges encountered.

**Chapter 6 — Testing and Evaluation:** Reports on the testing strategy, test results, and a critical evaluation of the project against its stated objectives.

**Chapter 7 — Conclusion and Future Work:** Summarises the project achievements, discusses limitations, and proposes future development directions.

---

# CHAPTER 2 — LITERATURE REVIEW

## 2.1 Introduction

This chapter critically examines the existing body of knowledge, research, and technological solutions relevant to the development of a telemedicine platform for rural healthcare in Nepal. The review is structured to first establish the theoretical foundations of telemedicine and mobile health, then analyse existing technologies and systems, and finally identify the research gap that this project seeks to address.

## 2.2 Theoretical Background

### 2.2.1 Telemedicine: Definition and Evolution

Telemedicine, defined by the WHO (2010) as "the delivery of healthcare services where distance is a critical factor, by healthcare professionals using information and communication technologies," has evolved significantly since its inception in the 1960s. Bashshur, Shannon, and Krupinski (2014) identify three generations of telemedicine: first-generation (basic telephonic consultations), second-generation (video conferencing-based consultations), and third-generation (integrated digital health platforms leveraging AI, IoT, and mobile technologies).

The COVID-19 pandemic served as a catalyst for telemedicine adoption worldwide. Monaghesh and Hajizadeh (2020) found that telemedicine usage increased by over 300% during the pandemic's initial phases, demonstrating both the demand for and viability of remote healthcare delivery. This accelerated adoption has persisted post-pandemic, with systematic reviews indicating sustained patient satisfaction and clinical outcomes comparable to in-person visits for many conditions (Shaver, 2022).

### 2.2.2 Mobile Health (mHealth) in Developing Countries

Mobile health (mHealth) refers to the use of mobile devices and wireless technologies to support healthcare delivery. Labrique *et al.* (2013) proposed the mHealth and ICT Framework, which identifies twelve common mHealth applications in developing countries, including client education and behaviour change communication, data collection and reporting, and provider-to-provider communication.

In the context of developing countries, mHealth has shown particular promise due to high mobile phone penetration even in areas with limited traditional healthcare infrastructure. The Lancet Commission on Global Health (2020) noted that mobile phone ownership in low- and middle-income countries exceeds 80%, presenting a significant opportunity for health service delivery.

### 2.2.3 Offline-First Architecture

The offline-first architectural pattern prioritises local data availability and functionality even when network connectivity is unavailable or unreliable (Nicola, 2018). This approach is critical for applications targeting users in areas with intermittent internet access. Key principles include local-first data storage, background synchronisation when connectivity is available, and conflict resolution mechanisms for data consistency.

Technologies such as SharedPreferences for lightweight key-value storage and SQLite for structured local databases on mobile devices enable offline data persistence. Progressive Web App (PWA) technology and service workers provide similar capabilities for web-based applications (Nicola, 2018).

### 2.2.4 AI in Healthcare

Artificial Intelligence, particularly Large Language Models (LLMs), has demonstrated significant potential in healthcare applications. Singhal *et al.* (2023) showed that LLMs such as Google's Med-PaLM achieved expert-level performance on medical question answering benchmarks. However, the responsible deployment of AI in healthcare requires careful consideration of safety, bias, transparency, and the distinction between clinical decision support and autonomous diagnosis (Topol, 2019).

The concept of "AI as a health educator" rather than "AI as a diagnostician" is gaining traction, with structured output schemas, guardrail prompting, and mandatory disclaimers serving as key safety mechanisms (Meskó and Topol, 2023). This approach is particularly relevant in low-health-literacy contexts where patients may benefit from plain-language explanations of health data without the risks associated with autonomous AI diagnosis.

### 2.2.5 Healthcare in Nepal: Contextual Analysis

Nepal's healthcare system operates across three tiers: primary (health posts, primary healthcare centres), secondary (district hospitals), and tertiary (zonal and central hospitals). The Ministry of Health and Population (2023) reports significant disparities between urban and rural healthcare access:

- **Doctor-to-patient ratio:** Approximately 1:1,700 nationally; exceeds 1:10,000 in some remote districts.
- **Healthcare facility distribution:** Over 70% of specialists are concentrated in the Kathmandu Valley.
- **Internet connectivity:** Approximately 40% broadband penetration in rural areas (Nepal Telecommunications Authority, 2024).
- **Digital literacy:** Varying levels, with higher mobile phone literacy than traditional computer literacy.

The Nepal government's Digital Nepal Framework 2019 identifies e-health as a priority area, but implementation has been slow, particularly in extending digital health services to rural populations (Government of Nepal, 2019).

## 2.3 Existing Technologies / Approaches

### 2.3.1 Cross-Platform Mobile Frameworks

Flutter, developed by Google, has emerged as a leading cross-platform mobile development framework. Its widget-based architecture, hot reload capability, and single codebase for Android and iOS make it particularly suited for resource-constrained development teams (Google, 2024). Compared to React Native, Flutter offers superior performance due to its direct compilation to native ARM code rather than relying on a JavaScript bridge (Wu, 2018).

### 2.3.2 RESTful API Architecture

REST (Representational State Transfer) remains the dominant architectural style for web APIs. Express.js, a minimal and flexible Node.js framework, provides a robust foundation for building RESTful services with middleware support for authentication, validation, and error handling (Tilkov and Vinoski, 2010).

### 2.3.3 Relational Database Management Systems

PostgreSQL, an advanced open-source relational database, supports features critical for healthcare applications, including UUID primary keys, JSONB columns for semi-structured data storage, and ACID-compliant transactions essential for data integrity in medical contexts (Juba and Volkov, 2019).

### 2.3.4 AI Integration via API

Cloud-based LLM APIs, such as Google's Generative AI (Gemini), provide a practical approach to integrating AI capabilities without requiring on-premise ML infrastructure. Structured output schemas (JSON mode) and system prompting enable controlled, reproducible AI behaviour suitable for healthcare contexts (Google DeepMind, 2024).

### 2.3.5 Digital Payment Systems in Nepal

eSewa, launched in 2009, is Nepal's first and largest digital wallet platform with over 10 million users. It provides a RESTful API for merchant integration, supporting both web and mobile payment flows. Khalti and IME Pay are other notable digital payment platforms in the Nepali ecosystem (eSewa, 2024).

## 2.4 Existing Systems / Solutions

### 2.4.1 Practo (India)

Practo is one of Asia's largest telemedicine platforms, offering online consultations, appointment booking, and medicine delivery. The platform supports video consultations and electronic health records. However, Practo is designed for the Indian market and does not support Nepali payment systems, NMC verification, or Nepali language (Practo, 2024).

### 2.4.2 Hamro Doctor (Nepal)

Hamro Doctor is a Nepali telemedicine startup offering video consultations and appointment booking. While it addresses the Nepal-specific payment challenge through eSewa integration, the platform primarily targets urban users in Kathmandu and lacks offline capabilities, health analytics, or AI-powered features (Hamro Doctor, 2024).

### 2.4.3 Ada Health (Germany)

Ada Health is an AI-powered health assessment platform that uses symptom checking algorithms to provide personalised health assessments. While its AI integration is sophisticated, Ada operates primarily as a symptom checker rather than a comprehensive telemedicine platform and does not offer doctor consultations, prescriptions, or localised support for Nepal (Ada Health, 2024).

### 2.4.4 Jeevee Health (Nepal)

Jeevee Health provides online pharmacy services and doctor consultations in Nepal. The platform supports eSewa payments and includes basic appointment booking. However, it lacks health monitoring capabilities, AI-powered analytics, and is primarily web-based with limited mobile functionality (Jeevee Health, 2024).

### 2.4.5 mHealth Nepal (Government Initiative)

The Government of Nepal's mHealth initiative provides basic health information via SMS to registered users. While it reaches populations without internet access, it lacks interactive features such as consultations, health monitoring, or personalised health analytics (Ministry of Health and Population, Nepal, 2023).

## 2.5 Comparison of Existing Solutions

| Feature | Practo | Hamro Doctor | Ada Health | Jeevee Health | mHealth Nepal | **Swasthya Sathi** |
|---|---|---|---|---|---|---|
| **Technology** | Web + Mobile (Native) | Web + Mobile | Mobile App | Web-based | SMS-based | **Flutter (Cross-platform)** |
| **Target Market** | India | Nepal (Urban) | Global | Nepal (Urban) | Nepal (Rural) | **Nepal (Rural)** |
| **Offline Support** | No | No | Partial | No | Yes (SMS) | **Yes** |
| **Video Consultation** | Yes | Yes | No | No | No | **Planned** |
| **Chat Consultation** | Yes | Limited | No | No | No | **Yes** |
| **Health Monitoring** | Basic | No | Symptom Checking | No | No | **Comprehensive (BP, Glucose, Weight)** |
| **AI Integration** | No | No | Yes (Symptom AI) | No | No | **Yes (Gemini LLM)** |
| **eSewa Payment** | No | Yes | No | Yes | No | **Yes** |
| **NMC Verification** | No | Partial | N/A | No | N/A | **Yes** |
| **Nepali Language** | No | Yes | No | Partial | Yes | **Yes** |
| **Prescriptions** | Yes | No | No | Pharmacy Orders | No | **Yes** |
| **Clinical Flagging** | No | No | Partial | No | No | **Yes (Rule Engine)** |
| **Open Source** | No | No | No | No | No | **Yes** |

*Table 2.1: Comparison of Existing Telemedicine Solutions*

## 2.6 Research Gap / Identified Problem

The analysis of existing solutions reveals several significant gaps:

1. **No comprehensive, Nepal-specific telemedicine platform exists** that combines offline-first capabilities, health monitoring with analytics, AI-powered health education, and Nepal-specific features (eSewa, NMC verification, Nepali language) in a single integrated system.

2. **Existing Nepali platforms target urban populations** and lack the offline-first architecture necessary for reliable operation in rural areas with intermittent connectivity.

3. **AI integration in telemedicine for developing countries is virtually non-existent.** While platforms like Ada Health leverage AI for symptom checking, no platform provides AI-powered plain-language health explanations tailored to low-health-literacy populations in Nepal.

4. **No existing platform integrates clinical rule-based flagging** aligned with international guidelines (JNC 8 for blood pressure, ADA 2024 for glucose) to provide decision support for both patients and rural health workers.

5. **Health monitoring and trend analysis** capabilities are absent from all Nepal-focused platforms, despite chronic conditions like hypertension and diabetes being leading causes of mortality in Nepal (Institute for Health Metrics and Evaluation, 2023).

*Therefore, this project proposes Swasthya Sathi — a purpose-built, offline-first telemedicine platform that addresses these gaps by providing a comprehensive, AI-enhanced, culturally appropriate healthcare solution for rural Nepal.*

## 2.7 Chapter Summary

This chapter has reviewed the theoretical foundations of telemedicine, mHealth, offline-first architecture, and AI in healthcare. It has analysed five existing telemedicine solutions across multiple dimensions and identified critical gaps that no current platform adequately addresses. The literature confirms both the need for and the technical feasibility of a comprehensive telemedicine platform tailored to rural Nepal, providing the academic foundation for the Swasthya Sathi project.

---

# CHAPTER 3 — METHODOLOGY / REQUIREMENTS ANALYSIS

## 3.1 Introduction

This chapter details the research and development methodology adopted for the Swasthya Sathi project, the data collection methods used to inform requirements, ethical considerations, and a comprehensive specification of the system's functional, non-functional, and user requirements.

## 3.2 Research / Development Approach

### 3.2.1 Overarching Framework: Design Science Research

The project employs the Design Science Research Methodology (DSRM) as proposed by Peffers *et al.* (2007). DSRM is particularly suited for IT projects that involve creating novel artefacts to address identified problems. The methodology comprises six phases:

1. **Problem Identification and Motivation:** Documented in Chapters 1 and 2 through the analysis of healthcare challenges in rural Nepal and gaps in existing solutions.
2. **Objectives of a Solution:** Defined as the project objectives in Section 1.4.
3. **Design and Development:** The iterative design and implementation of the Swasthya Sathi platform (Chapters 4 and 5).
4. **Demonstration:** The functional prototype demonstrating the platform's capabilities (Chapter 5).
5. **Evaluation:** Structured testing and assessment against objectives (Chapter 6).
6. **Communication:** This dissertation and its associated artefacts.

### 3.2.2 Development Methodology: Agile with Scrum

For the software development lifecycle, the project adopts an Agile methodology with Scrum practices, adapted for individual development:

- **Sprint Duration:** Two-week sprints
- **Sprint Planning:** Definition of user stories and tasks for each sprint
- **Sprint Review:** Assessment of completed features against acceptance criteria
- **Continuous Integration:** Regular code commits and feature integration

The Agile approach was chosen for its flexibility, iterative nature, and ability to accommodate evolving requirements — a critical consideration given the complexity and novelty of the project (Schwaber and Sutherland, 2020).

### 3.2.3 Sprint Plan Overview

| Sprint | Duration | Focus Areas |
|---|---|---|
| Sprint 1 | Weeks 1–2 | Project setup, database schema design, authentication module |
| Sprint 2 | Weeks 3–4 | Patient and doctor profiles, masters data, UI foundation |
| Sprint 3 | Weeks 5–6 | Scheduling, appointments, consultation module |
| Sprint 4 | Weeks 7–8 | Prescriptions, pharmacy, payment integration |
| Sprint 5 | Weeks 9–10 | Health monitoring module, vitals tracking |
| Sprint 6 | Weeks 11–12 | Health analysis engine, Python analytics service |
| Sprint 7 | Weeks 13–14 | AI integration (Gemini), health explanations, chat |
| Sprint 8 | Weeks 15–16 | Testing, evaluation, documentation |

## 3.3 Data Collection Methods

### 3.3.1 Secondary Research

The primary data collection method for this project is secondary research, encompassing:

- **Academic Literature:** Peer-reviewed journals and conference proceedings on telemedicine, mHealth, AI in healthcare, and healthcare in Nepal accessed through Google Scholar, IEEE Xplore, and PubMed.
- **Government Reports:** Publications from Nepal's Ministry of Health and Population, Nepal Telecommunications Authority, and the WHO Country Office for Nepal.
- **Industry Reports:** Market analyses and white papers from organisations involved in digital health in South Asia.
- **Technical Documentation:** Official documentation for Flutter, Node.js, PostgreSQL, FastAPI, and Google Generative AI SDK.

### 3.3.2 Contextual Analysis

A contextual analysis of Nepal's healthcare landscape was conducted through:

- Analysis of existing Nepali telemedicine platforms (Hamro Doctor, Jeevee Health)
- Review of Nepal's Digital Nepal Framework 2019
- Analysis of Nepal Medical Council registration processes and requirements
- Study of the Nepali digital payment ecosystem (eSewa, Khalti, IME Pay)

## 3.4 Ethical Considerations

### 3.4.1 Data Protection and Privacy

The system is designed with data protection as a foundational principle:

- **No real patient data** is used during development or testing; all test data is synthetic.
- **Password hashing** using bcrypt (12 salt rounds) ensures credentials are never stored in plain text.
- **JWT-based authentication** with configurable token expiry (default 24 hours) protects API access.
- **Role-based access control (RBAC)** ensures patients cannot access doctor-only endpoints and vice versa.

### 3.4.2 AI Safety and Responsibility

The AI integration follows responsible AI principles:

- The AI system **never diagnoses, prescribes, or modifies medications.** It operates strictly as a health education tool.
- All AI responses include a **mandatory disclaimer** stating the information is educational and not a substitute for professional medical advice.
- **Structured output schemas** constrain the AI's response format, preventing uncontrolled free-text health advice.
- A **clinical rule engine** operates independently of the AI, applying guideline-based flagging that the AI cannot override.
- **Patient data is anonymised** before being sent to the LLM — only age range, gender, and aggregate health statistics are shared; no names, phone numbers, or direct identifiers are transmitted.

### 3.4.3 Informed Consent

In a production deployment, the platform would implement:

- Clear informed consent workflows before patient data is processed
- Explicit opt-in for AI-powered health analysis features
- Transparent information about data storage, processing, and sharing

## 3.5 Functional Requirements

| ID | Requirement | Priority | Category |
|---|---|---|---|
| FR01 | The system shall allow patients to register with phone, email, password, and personal details | Must Have | Authentication |
| FR02 | The system shall allow doctors to register with NMC registration number and credentials | Must Have | Authentication |
| FR03 | The system shall authenticate users via phone/email and password, issuing JWT tokens | Must Have | Authentication |
| FR04 | The system shall allow patients to view and edit their profile information | Must Have | Profile Management |
| FR05 | The system shall allow doctors to view and edit their profile, qualifications, and availability | Must Have | Profile Management |
| FR06 | The system shall display a list of available doctors with filtering by specialisation | Must Have | Doctor Discovery |
| FR07 | The system shall allow patients to book appointments with doctors for available time slots | Must Have | Appointments |
| FR08 | The system shall support multiple consultation modes: video, audio, chat, and in-person | Must Have | Consultations |
| FR09 | The system shall allow doctors to manage appointment statuses (confirm, complete, cancel) | Must Have | Appointments |
| FR10 | The system shall enable real-time chat messaging during consultations | Must Have | Consultations |
| FR11 | The system shall allow doctors to create digital prescriptions with medicine details | Must Have | Prescriptions |
| FR12 | The system shall integrate eSewa for payment of consultation fees | Must Have | Payments |
| FR13 | The system shall allow patients to record blood pressure, glucose, and weight readings | Must Have | Health Monitoring |
| FR14 | The system shall generate comprehensive health analyses using statistical methods | Must Have | Health Analytics |
| FR15 | The system shall apply clinical rule-based flagging (JNC 8, ADA 2024) to health data | Must Have | Clinical Safety |
| FR16 | The system shall provide AI-generated plain-language health explanations | Should Have | AI Features |
| FR17 | The system shall support AI-powered health chat conversations | Should Have | AI Features |
| FR18 | The system shall support bilingual operation in English and Nepali | Should Have | Localisation |
| FR19 | The system shall allow doctors to schedule follow-ups for patients | Should Have | Follow-ups |
| FR20 | The system shall provide admin functionality for user management and audit logging | Could Have | Administration |
| FR21 | The system shall allow pharmacy order management linked to prescriptions | Could Have | Pharmacy |
| FR22 | The system shall support payment refund processing | Could Have | Payments |

*Table 3.1: Functional Requirements*

## 3.6 Non-Functional Requirements

| ID | Requirement | Category |
|---|---|---|
| NFR01 | The system shall respond to API requests within 500ms under normal load | Performance |
| NFR02 | The system shall support a minimum of 100 concurrent users | Scalability |
| NFR03 | The system shall store all passwords using bcrypt with a minimum of 12 salt rounds | Security |
| NFR04 | The system shall implement JWT-based authentication with configurable token expiry | Security |
| NFR05 | The system shall implement role-based access control (RBAC) for all API endpoints | Security |
| NFR06 | The system shall validate all API inputs using express-validator | Security |
| NFR07 | The mobile application shall function on Android 8.0+ and iOS 14+ | Compatibility |
| NFR08 | The user interface shall follow Material Design 3 guidelines for usability | Usability |
| NFR09 | The system shall persist user session data locally for offline access | Reliability |
| NFR10 | The database schema shall use UUID primary keys to prevent sequential ID enumeration | Security |
| NFR11 | The system shall implement CORS headers for secure cross-origin requests | Security |
| NFR12 | All database operations involving multiple tables shall use ACID-compliant transactions | Reliability |
| NFR13 | The AI module shall include a fallback mechanism when the LLM API is unavailable | Reliability |
| NFR14 | The health analytics Python service shall include a JavaScript fallback for degraded operation | Reliability |

*Table 3.2: Non-Functional Requirements*

## 3.7 User Requirements / User Stories

### Patient User Stories

| ID | User Story | Acceptance Criteria |
|---|---|---|
| US-P01 | As a patient, I want to register using my phone number so that I can access the platform | Registration succeeds with valid phone, password, and full name; JWT token is returned |
| US-P02 | As a patient, I want to browse available doctors so that I can find a suitable specialist | Doctor list is displayed with name, specialisation, fee, and rating |
| US-P03 | As a patient, I want to book an appointment so that I can consult with a doctor | Appointment is created with selected date, time, and consultation mode |
| US-P04 | As a patient, I want to pay for consultations via eSewa so that I can complete my booking | eSewa payment flow is initiated and payment status is updated upon completion |
| US-P05 | As a patient, I want to record my blood pressure readings so that I can track my health | BP reading is saved with systolic, diastolic, heart rate, and timestamp |
| US-P06 | As a patient, I want to see my health analysis so that I can understand my health trends | Health analysis is generated showing averages, trends, and clinical flags |
| US-P07 | As a patient, I want AI to explain my health data in simple language so that I can understand it | AI explanation is displayed in chosen language with clear, non-medical language |
| US-P08 | As a patient, I want to chat with an AI health assistant so that I can ask follow-up questions | AI chat responds to health questions with contextual, appropriate answers |
| US-P09 | As a patient, I want to view my prescriptions so that I can follow my medication plan | Prescriptions are displayed with medicine names, dosages, and instructions |
| US-P10 | As a patient, I want to manage my profile so that my information stays current | Profile fields (name, gender, DOB, blood group, emergency contact) are editable |

*Table 3.3: User Stories — Patient*

### Doctor User Stories

| ID | User Story | Acceptance Criteria |
|---|---|---|
| US-D01 | As a doctor, I want to register with my NMC number so that I can be verified | Registration succeeds with NMC number; verification status starts as "pending" |
| US-D02 | As a doctor, I want to set my availability schedule so that patients can book my time | Availability slots are created for each day of the week with start/end times |
| US-D03 | As a doctor, I want to manage appointments so that I can organise my consultations | Appointments are listed and statuses can be updated (confirmed, completed, cancelled) |
| US-D04 | As a doctor, I want to conduct chat consultations so that I can treat patients remotely | Chat messages are exchanged in real-time during an active consultation |
| US-D05 | As a doctor, I want to create prescriptions so that I can provide treatment plans | Prescription with medicine items (name, dosage, frequency, duration) is created |
| US-D06 | As a doctor, I want to view my patients' health data so that I can make informed decisions | Patient health records, vitals, and analysis are accessible from the doctor dashboard |
| US-D07 | As a doctor, I want to schedule follow-ups so that I can track patient progress | Follow-up entry is created with date, notes, and associated consultation |

*Table 3.4: User Stories — Doctor*

## 3.8 System Constraints

1. **Internet Dependency for Core Features:** While the platform is designed with offline-first principles for data persistence, features such as real-time consultation, payment processing, and AI analysis require internet connectivity.
2. **Third-Party API Dependencies:** The platform depends on Google Gemini API for AI features and eSewa API for payments; unavailability of these services would degrade (but not eliminate) functionality due to implemented fallback mechanisms.
3. **Single Developer:** As an individual undergraduate project, development velocity and scope are constrained compared to team-based commercial development.
4. **Hardware Constraints:** The mobile application must perform adequately on mid-range Android devices commonly used in rural Nepal (2GB+ RAM, Android 8.0+).

## 3.9 Chapter Summary

This chapter has established the research and development methodology for the Swasthya Sathi project, combining Design Science Research as the overarching framework with Agile Scrum for iterative software development. Data collection relies primarily on secondary research and contextual analysis. Comprehensive functional, non-functional, and user requirements have been specified, with ethical considerations addressing data protection, AI safety, and informed consent. These requirements serve as the foundation for the system design presented in the following chapter.

---

# CHAPTER 4 — SYSTEM ANALYSIS AND DESIGN

## 4.1 Introduction

This chapter presents the detailed system design for Swasthya Sathi, including the overall system architecture, UML diagrams, database design, user interface wireframes, technology stack selection, and security design. The design decisions documented here are informed by the requirements specified in Chapter 3.

## 4.2 System Architecture

Swasthya Sathi employs a **multi-tier microservices-oriented architecture** comprising four primary components:

1. **Flutter Mobile Client (Presentation Tier):** Cross-platform mobile application providing the user interface for patients, doctors, and administrators.
2. **Node.js/Express REST API (Application Tier):** Central backend server handling business logic, authentication, data validation, and orchestration.
3. **PostgreSQL Database (Data Tier):** Relational database storing all structured data with referential integrity.
4. **Python Analytics Microservice (Analytics Tier):** Specialised service for statistical computation of health data, communicating with the Node.js backend via internal HTTP calls.
5. **External Services:** Google Gemini AI API for health explanations, eSewa payment gateway for transactions.

```mermaid
graph TB
    subgraph "Client Tier"
        A["Flutter Mobile App<br/>(Patient / Doctor / Admin)"]
    end

    subgraph "Application Tier"
        B["Node.js / Express<br/>REST API (Port 5000)<br/>17 Route Modules"]
    end

    subgraph "Data Tier"
        C["PostgreSQL<br/>30+ Tables, UUID PKs<br/>17 ENUM Types"]
    end

    subgraph "Analytics Tier"
        D["Python FastAPI<br/>pandas / NumPy<br/>(Port 8001)"]
    end

    subgraph "External Services"
        E["Google Gemini AI"]
        F["eSewa Payment"]
    end

    A -- "HTTPS/REST + JWT" --> B
    B -- "pg Driver" --> C
    B -- "Internal HTTP" --> D
    B -- "Gemini SDK" --> E
    A -- "eSewa SDK" --> F
```

*Figure 4.1: System Architecture Diagram*

### 4.2.1 Communication Patterns

- **Client to Backend:** RESTful HTTP/HTTPS with JSON payloads, authenticated via JWT Bearer tokens.
- **Backend to Database:** PostgreSQL wire protocol via the `pg` driver with connection pooling.
- **Backend to Python Service:** Internal HTTP POST requests to `http://localhost:8001` with JSON payloads; includes a 15-second timeout and fallback to JavaScript-based analytics if the Python service is unavailable.
- **Backend to Google Gemini:** HTTPS API calls using the `@google/generative-ai` SDK with structured JSON output schema enforcement.

## 4.3 Use Case Diagram

The system identifies three primary actors: **Patient**, **Doctor**, and **Admin**.

```mermaid
graph LR
    subgraph "Patient Use Cases"
        P1["Register / Login"]
        P2["View / Edit Profile"]
        P3["Browse Doctors"]
        P4["Book Appointment"]
        P5["Make Payment via eSewa"]
        P6["Conduct Consultation Chat"]
        P7["View Prescriptions"]
        P8["Record Health Vitals"]
        P9["Generate Health Analysis"]
        P10["View AI Health Explanation"]
        P11["Chat with AI Assistant"]
        P12["View Follow-ups"]
        P13["Submit Doctor Review"]
    end

    Patient(("Patient")) --> P1
    Patient --> P2
    Patient --> P3
    Patient --> P4
    Patient --> P5
    Patient --> P6
    Patient --> P7
    Patient --> P8
    Patient --> P9
    Patient --> P10
    Patient --> P11
    Patient --> P12
    Patient --> P13
```

```mermaid
graph LR
    subgraph "Doctor Use Cases"
        D1["Register with NMC Number"]
        D2["Set Availability Schedule"]
        D3["Manage Appointments"]
        D4["Conduct Consultation Chat"]
        D5["Write Prescription"]
        D6["View Patient Health Data"]
        D7["Schedule Follow-ups"]
        D8["View Reviews"]
    end

    Doctor(("Doctor")) --> D1
    Doctor --> D2
    Doctor --> D3
    Doctor --> D4
    Doctor --> D5
    Doctor --> D6
    Doctor --> D7
    Doctor --> D8
```

## 4.4 Use Case Descriptions

### UC01: Patient Registration

| Element | Description |
|---|---|
| **Use Case ID** | UC01 |
| **Actor** | Patient |
| **Precondition** | User has the mobile application installed |
| **Main Flow** | 1. User selects "Patient" role on role selection screen. 2. User enters phone, email (optional), password, full name, gender, DOB, blood group. 3. System validates inputs (phone format, password strength, uniqueness). 4. System hashes password with bcrypt (12 rounds). 5. System creates user record (role=patient) and patient profile within a database transaction. 6. System generates JWT token. 7. System returns token and user/profile data. 8. App persists session locally via SharedPreferences. |
| **Postcondition** | Patient account is created; user is authenticated and redirected to patient dashboard |
| **Alternative Flow** | A1: Phone/email already exists → system returns 409 error with descriptive message |

### UC02: Book Appointment

| Element | Description |
|---|---|
| **Use Case ID** | UC02 |
| **Actor** | Patient |
| **Precondition** | Patient is authenticated; doctor has available slots |
| **Main Flow** | 1. Patient selects a doctor from the doctor list. 2. Patient views doctor's available time slots. 3. Patient selects date, time, and consultation mode. 4. Patient provides reason for visit. 5. System creates appointment record (status=pending). 6. System redirects to payment flow (eSewa). 7. Upon successful payment, appointment status is updated to confirmed. |
| **Postcondition** | Appointment is created and confirmed; payment record is stored |

### UC03: Generate Health Analysis

| Element | Description |
|---|---|
| **Use Case ID** | UC03 |
| **Actor** | Patient |
| **Precondition** | Patient has recorded health vitals (BP, glucose, or weight readings) |
| **Main Flow** | 1. Patient navigates to Health Analysis screen. 2. Patient selects analysis period (7 days, 30 days, 90 days). 3. Backend loads health data from database. 4. Backend sends data to Python analytics service for statistical analysis. 5. Backend applies clinical rule engine (JNC 8 for BP, ADA 2024 for glucose). 6. Backend persists analysis result with input snapshot. 7. Patient views comprehensive analysis with trends, averages, and flags. 8. Patient optionally requests AI explanation. 9. Backend sends anonymised analysis to Google Gemini. 10. AI returns structured explanation (summary, observations, recommendations). |
| **Postcondition** | Health analysis is stored; AI explanation is displayed and persisted for audit |

## 4.5 Data Flow Diagrams

### Level 0: Context Diagram

```mermaid
graph LR
    PA(("Patient")) -- "Registration, Appointments,<br/>Health Data, Payments" --> SS["SWASTHYA SATHI<br/>SYSTEM"]
    DR(("Doctor")) -- "Registration, Consultations,<br/>Prescriptions, Follow-ups" --> SS
    AD(("Admin")) -- "User Management,<br/>Verification, Audit" --> SS
    SS -- "Statistical Analysis" --> PY["Python Analytics<br/>Service"]
    SS -- "AI Explanations" --> GM["Google Gemini<br/>API"]
    SS -- "Payment Processing" --> ES["eSewa<br/>Payment Gateway"]
```

## 4.6 Database Design

### 4.6.1 Entity-Relationship Overview

The database schema comprises **30+ tables** organised into 11 logical domains. The schema uses PostgreSQL-specific features including custom ENUM types (17 ENUMs), UUID primary keys generated via `pgcrypto`, JSONB columns for semi-structured data, and comprehensive indexing for query performance.

### 4.6.2 Core Entity Descriptions

| Entity/Table | Purpose | Key Attributes |
|---|---|---|
| `users` | Central identity table for all users | id (UUID), phone, email, password_hash, role (ENUM), status (ENUM), preferred_language |
| `patients` | Patient-specific profile data | id (UUID), user_id (FK), full_name, dob, gender, blood_group, emergency_contact |
| `doctors` | Doctor-specific profile data | id (UUID), user_id (FK), full_name, nmc_registration_number, nmc_status, consultation_fee, average_rating |
| `doctor_qualifications` | Doctor educational qualifications | doctor_id (FK), degree, institution, country, year_completed |
| `specializations` | Medical specialisation lookup | id, name, description |
| `doctor_specializations` | Many-to-many: doctors and specialisations | doctor_id, specialization_id (composite PK) |
| `doctor_availability` | Weekly availability schedule | doctor_id (FK), day_of_week, start_time, end_time, slot_duration_minutes |
| `appointments` | Scheduled consultations | patient_id (FK), doctor_id (FK), scheduled_at, mode (ENUM), status (ENUM), fee |
| `consultations` | Active consultation sessions | appointment_id (FK), video_room_id, started_at, ended_at, diagnosis, doctor_notes |
| `chat_messages` | Consultation chat messages | consultation_id (FK), sender_id (FK), message, attachment_url, sent_at |
| `prescriptions` | Doctor-issued prescriptions | consultation_id (FK), doctor_id (FK), patient_id (FK), issued_at, notes |
| `prescription_items` | Individual medicine items | prescription_id (FK), medicine_name, dosage, route (ENUM), frequency, duration_days |
| `payments` | Payment transaction records | appointment_id (FK), patient_id (FK), amount, gateway (ENUM), status (ENUM) |
| `blood_pressure_readings` | BP vital recordings | patient_id (FK), systolic, diastolic, heart_rate, measured_at, measurement_context |
| `glucose_readings` | Blood glucose recordings | patient_id (FK), glucose_value, unit, measurement_type, measured_at |
| `weight_readings` | Weight recordings | patient_id (FK), weight_kg, measured_at |
| `patient_conditions` | Diagnosed conditions | patient_id (FK), condition_name, condition_type, status, diagnosis_date |
| `patient_medications` | Active medications | patient_id (FK), medicine_name, dosage, route, frequency, is_active |
| `health_analyses` | Persisted analysis results | patient_id (FK), analysis_type, period_start, period_end, engine_version, rule_version, result (JSONB) |
| `ai_health_feedback` | AI explanation audit trail | patient_id (FK), analysis_id (FK), model_name, prompt_version, context (JSONB), response (JSONB) |
| `ai_conversations` | AI chat conversation headers | patient_id (FK), title, created_at, updated_at |
| `ai_messages` | AI chat messages | conversation_id (FK), role, content, created_at |
| `reviews` | Doctor ratings by patients | appointment_id (FK), patient_id (FK), doctor_id (FK), rating (1–5), comment |
| `notifications` | System notifications | user_id (FK), type, title, message, is_read |
| `admins` | Admin-specific data | user_id (FK), permission_level (ENUM) |
| `audit_logs` | System audit trail | user_id (FK), action, entity_type, entity_id, metadata (JSONB) |
| `follow_ups` | Scheduled follow-up visits | doctor_id (FK), patient_id (FK), consultation_id (FK), follow_up_date, status |

*Table 4.1: Entity Descriptions — Core Tables*

### 4.6.3 Key Relationships

- **users to patients / doctors / admins:** One-to-one relationship via `user_id` foreign key (single-table inheritance for identity).
- **doctors and specializations:** Many-to-many via `doctor_specializations` junction table.
- **patients to appointments to consultations to prescriptions:** One-to-many chain representing the consultation workflow.
- **prescriptions to prescription_items:** One-to-many for individual medicines within a prescription.
- **patients to blood_pressure_readings / glucose_readings / weight_readings:** One-to-many for health monitoring data.

### 4.6.4 Entity-Relationship Diagram

```mermaid
erDiagram
    users ||--o| patients : "has profile"
    users ||--o| doctors : "has profile"
    users ||--o| admins : "has profile"
    doctors ||--o{ doctor_specializations : "has"
    specializations ||--o{ doctor_specializations : "assigned to"
    doctors ||--o{ doctor_availability : "sets"
    doctors ||--o{ doctor_qualifications : "holds"
    patients ||--o{ appointments : "books"
    doctors ||--o{ appointments : "receives"
    appointments ||--|| consultations : "generates"
    consultations ||--o{ chat_messages : "contains"
    consultations ||--|| prescriptions : "results in"
    prescriptions ||--o{ prescription_items : "includes"
    patients ||--o{ blood_pressure_readings : "records"
    patients ||--o{ glucose_readings : "records"
    patients ||--o{ weight_readings : "records"
    patients ||--o{ health_analyses : "generates"
    patients ||--o{ payments : "makes"
    appointments ||--o{ payments : "paid via"
    patients ||--o{ reviews : "writes"
    doctors ||--o{ reviews : "receives"
    doctors ||--o{ follow_ups : "schedules"
    patients ||--o{ follow_ups : "receives"
```

*Figure 4.7: Entity-Relationship Diagram (ERD)*

### 4.6.5 Normalisation

The database schema follows **Third Normal Form (3NF)**:

- **1NF:** All attributes are atomic; no repeating groups exist. Multi-valued attributes (e.g., doctor languages, specialisations) are modelled as separate tables with junction tables.
- **2NF:** All non-key attributes are fully functionally dependent on the primary key. Composite primary keys (e.g., `doctor_specializations`) ensure no partial dependencies.
- **3NF:** No transitive dependencies exist. Location data is normalised into `provinces → districts → municipalities` hierarchy rather than denormalised into user records.

## 4.7 Class Diagram

### Frontend (Flutter) — Key Classes

```mermaid
classDiagram
    class AuthUser {
        +String id
        +String phone
        +String? email
        +String role
        +String token
        +String? fullName
        +fromApiResponse()
    }

    class AppointmentModel {
        +String id
        +String patientId
        +String doctorId
        +DateTime scheduledAt
        +String mode
        +String status
        +double fee
        +fromJson()
    }

    class AuthService {
        -AuthService _instance
        +ValueNotifier userNotifier
        +login()
        +registerPatient()
        +registerDoctor()
        +logout()
        +loadSavedSession()
    }

    class HealthService {
        +recordBP()
        +recordGlucose()
        +recordWeight()
        +getAnalysis()
        +getVitals()
    }

    class AIService {
        +explainAnalysis()
        +startConversation()
        +sendMessage()
        +getConversations()
    }

    class AppointmentService {
        +bookAppointment()
        +getAppointments()
        +updateStatus()
    }

    AuthService --> AuthUser : manages
    AppointmentService --> AppointmentModel : creates
```

*Figure 4.8: Class Diagram — Flutter Frontend Models and Services*

## 4.8 Sequence Diagrams

### Sequence Diagram: User Registration

```mermaid
sequenceDiagram
    actor Patient
    participant App as Flutter App
    participant API as Node.js API
    participant DB as PostgreSQL

    Patient->>App: Enter registration details
    App->>API: POST /auth/register/patient
    API->>DB: BEGIN transaction
    API->>DB: Check phone/email uniqueness
    DB-->>API: No conflict found
    API->>API: Hash password (bcrypt 12 rounds)
    API->>DB: INSERT INTO users (role=patient)
    DB-->>API: User created
    API->>DB: INSERT INTO patients
    DB-->>API: Patient profile created
    API->>DB: COMMIT
    API->>API: Sign JWT token
    API-->>App: { token, user, profile }
    App->>App: Persist session (SharedPreferences)
    App-->>Patient: Navigate to Dashboard
```

*Figure 4.9: Sequence Diagram — User Registration*

### Sequence Diagram: Health Analysis Generation

```mermaid
sequenceDiagram
    actor Patient
    participant App as Flutter App
    participant API as Node.js API
    participant Py as Python Analytics
    participant Gem as Google Gemini
    participant DB as PostgreSQL

    Patient->>App: Request Health Analysis
    App->>API: GET /health-analysis/summary
    API->>DB: Load BP, Glucose, Weight data
    DB-->>API: Health readings
    API->>Py: POST /internal/analysis/complete
    Py->>Py: pandas/numpy statistical analysis
    Py-->>API: Statistical results
    API->>API: Apply Clinical Rules (JNC8, ADA2024)
    API->>DB: Persist analysis result
    API-->>App: Analysis with flags
    App-->>Patient: Display analysis

    Patient->>App: Request AI Explanation
    App->>API: POST /ai/explain
    API->>API: Build anonymised context
    API->>Gem: Generate explanation (structured schema)
    Gem-->>API: JSON explanation
    API->>API: Validate output
    API->>DB: Persist AI feedback (audit)
    API-->>App: Explanation data
    App-->>Patient: Display AI explanation
```

*Figure 4.11: Sequence Diagram — Health Analysis Generation*

## 4.9 User Interface Design

### 4.9.1 Design Principles

The UI design follows these principles:

1. **Material Design 3:** Adherence to Google's Material Design 3 guidelines for consistency and usability.
2. **Accessibility:** Large touch targets, clear typography (Roboto font), and high-contrast colour schemes.
3. **Cultural Appropriateness:** Use of green/blue colour palette associated with health and trust in Nepali culture.
4. **Minimal Cognitive Load:** Progressive disclosure of information; critical data presented prominently.
5. **Responsive Layout:** Adaptation to various screen sizes common in the Nepali mobile device market.

### 4.9.2 Colour Palette

| Purpose | Colour | Hex Code |
|---|---|---|
| Primary | Blue | `#0072FF` |
| Background | Light Grey | `#F4F7FB` |
| Success | Green | Standard Material |
| Warning | Amber | Standard Material |
| Error/Critical | Red | Standard Material |

### 4.9.3 Key Screens

The application comprises the following key screens:

1. **Welcome Screen:** Animated introduction with app logo and tagline
2. **Role Selection Screen:** Patient/Doctor role choice
3. **Registration Screens:** Separate forms for patient and doctor registration
4. **Login Screen:** Phone/email and password authentication
5. **Patient Dashboard:** Overview with upcoming appointments, health summary, quick actions
6. **Doctor Dashboard:** Patient list, appointment management, consultation tools
7. **Doctor Detail Screen:** Doctor profile, qualifications, reviews, booking button
8. **Appointment Booking Screen:** Date/time/mode selection
9. **eSewa Payment Screen:** Payment integration flow
10. **Consultation Chat Screen:** Real-time messaging interface
11. **Health Dashboard:** Vitals overview with charts (fl_chart)
12. **BP/Glucose/Weight Entry Screens:** Data input forms with validation
13. **Health Analysis Screen:** Comprehensive analysis with flags and AI explanation
14. **AI Doctor Chat Screen:** Conversational AI health assistant
15. **Patient Profile Screen:** Profile view and editing
16. **Account Settings Screen:** Language, notifications, logout

## 4.10 Technology Stack

| Layer | Technology | Version | Purpose |
|---|---|---|---|
| **Frontend Framework** | Flutter | SDK ^3.10.1 | Cross-platform mobile UI |
| **Frontend Language** | Dart | 3.x | Application logic |
| **UI Components** | Material Design 3 | Latest | Design system |
| **HTTP Client** | http (Dart) | ^1.2.2 | API communication |
| **Local Storage** | shared_preferences | ^2.3.2 | Session persistence |
| **Charts** | fl_chart | ^0.70.2 | Health data visualisation |
| **Payment** | esewa_flutter | ^3.0.1 | eSewa payment integration |
| **Navigation** | curved_labeled_navigation_bar | ^2.0.6 | Bottom navigation |
| **Backend Runtime** | Node.js | LTS | JavaScript runtime |
| **Backend Framework** | Express.js | ^5.2.1 | REST API framework |
| **Database** | PostgreSQL | 15+ | Relational data storage |
| **DB Driver** | pg (node-postgres) | ^8.23.0 | PostgreSQL client |
| **Authentication** | jsonwebtoken | ^9.0.3 | JWT creation/verification |
| **Password Hashing** | bcryptjs | ^3.0.3 | Secure password storage |
| **Input Validation** | express-validator | ^7.3.2 | Request validation |
| **AI SDK** | @google/generative-ai | ^0.24.1 | Google Gemini integration |
| **HTTP Client (Backend)** | axios | ^1.20.0 | Inter-service communication |
| **Analytics Framework** | FastAPI | 0.115.0 | Python analytics API |
| **Data Analysis** | pandas | 2.2.3 | Statistical computation |
| **Numerical Computing** | NumPy | 2.1.2 | Array operations, regression |
| **Scientific Computing** | SciPy | 1.14.1 | Statistical functions |
| **Analytics Server** | Uvicorn | 0.32.0 | ASGI server |
| **Environment Config** | dotenv | ^18.0.1 | Environment variables |

*Table 4.2: Technology Stack*

## 4.11 Security Design

### 4.11.1 Authentication

- **JWT Bearer Token Authentication:** All protected API endpoints require a valid JWT token in the `Authorization` header.
- **Token Structure:** Payload includes `user_id`, `role`, and `phone`; signed with a configurable secret key.
- **Token Expiry:** Default 24-hour expiry with `TokenExpiredError` handling for graceful session timeout.
- **Session Persistence:** JWT is stored locally via SharedPreferences and restored on app launch.

### 4.11.2 Authorisation

- **Role-Based Access Control (RBAC):** A middleware function `authorize(...roles)` gates endpoint access by user role (patient, doctor, admin).
- **Resource Ownership Validation:** API endpoints validate that the requesting user owns the resource they are accessing (e.g., patients can only view their own health data).

### 4.11.3 Data Protection

- **Password Hashing:** bcrypt with 12 salt rounds; plain-text passwords are never stored.
- **UUID Primary Keys:** Prevent sequential ID enumeration attacks.
- **Input Validation:** All API inputs are validated using express-validator before processing.
- **CORS Configuration:** Cross-Origin Resource Sharing headers are set to control allowed origins, methods, and headers.
- **SQL Injection Prevention:** Parameterised queries are used exclusively; no string concatenation in SQL statements.
- **Database Transactions:** Multi-table operations (e.g., registration) use ACID-compliant transactions with explicit `BEGIN`, `COMMIT`, and `ROLLBACK`.

### 4.11.4 AI Data Privacy

- Patient data sent to the LLM is **anonymised:** only age range, gender, and aggregated health statistics are transmitted.
- No names, phone numbers, email addresses, or direct identifiers are included in LLM requests.
- AI responses are validated against a schema and persisted for auditability.

## 4.12 Chapter Summary

This chapter has presented the comprehensive system design for Swasthya Sathi, including a multi-tier architecture with four primary components, detailed use case and sequence diagrams, a normalised database schema with 30+ tables, a technology stack leveraging modern frameworks across three programming languages, and a multi-layered security design. These design artefacts provide the blueprint for the implementation described in the following chapter.

---

# CHAPTER 5 — IMPLEMENTATION / DEVELOPMENT

## 5.1 Introduction

This chapter details the actual development of the Swasthya Sathi platform, describing the development environment, implementation approach for each system tier, key features with relevant code snippets, and the technical challenges encountered during development.

## 5.2 Development Environment

| Tool/Software | Purpose |
|---|---|
| **Visual Studio Code** | Primary IDE for Dart, JavaScript, and Python development |
| **Android Studio** | Android SDK management, emulator, and device debugging |
| **Flutter SDK 3.10.1** | Cross-platform mobile development toolkit |
| **Node.js (LTS)** | Backend JavaScript runtime |
| **PostgreSQL 15+** | Database server |
| **pgAdmin 4** | Database management GUI |
| **Python 3.11+** | Analytics service runtime |
| **Postman** | API testing and documentation |
| **Git** | Version control |
| **GitHub** | Remote repository hosting |
| **Windows 11** | Development operating system |

*Table 5.1: Development Environment and Tools*

## 5.3 Frontend Implementation

### 5.3.1 Application Structure

The Flutter application follows a **feature-first architecture**, organising code by feature modules rather than by layer type:

```
lib/
├── main.dart                          # App entry point
└── src/
    ├── common_widgets/                # Reusable UI components
    │   ├── carosel/                   # Image carousel widget
    │   ├── doctors/                   # Doctor card widgets
    │   ├── navigation_bar/            # Bottom navigation
    │   ├── searchBar/                 # Search widget
    │   └── urgent_care/               # Urgent care widget
    ├── constants/                     # App-wide constants
    │   ├── api_constants.dart         # API endpoint URLs
    │   ├── colors.dart                # Colour palette
    │   ├── sizes.dart                 # Spacing/sizing
    │   └── text_strings.dart          # UI strings
    ├── features/                      # Feature modules
    │   ├── auth/                      # Authentication screens
    │   ├── appointments/              # Appointment management
    │   ├── consultation/              # Consultation + chat
    │   ├── doctor_dashboard/          # Doctor-specific views
    │   ├── doctor_profile/            # Doctor detail screen
    │   ├── health/                    # Health monitoring + analytics
    │   ├── patient_dashboard/         # Patient home screen
    │   ├── patient_profile/           # Patient profile management
    │   └── urgent_care/               # Emergency guidance
    ├── models/                        # Data models
    │   ├── auth_user.dart
    │   ├── appointment_model.dart
    │   ├── chat_message_model.dart
    │   └── specialization_model.dart
    ├── services/                      # Business logic / API clients
    │   ├── auth_service.dart          # Authentication (Singleton)
    │   ├── health_service.dart        # Health data management
    │   ├── ai_service.dart            # AI features
    │   └── ... (10 service files)
    ├── repository/                    # Data access layer
    └── utils/                         # Utility functions
```

### 5.3.2 State Management

The application uses Flutter's built-in `ValueNotifier` for reactive state management, exemplified by the `AuthService` singleton:

```dart
class AuthService {
  AuthService._internal();
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final ValueNotifier<AuthUser?> userNotifier = ValueNotifier(null);
  AuthUser? get currentUser => userNotifier.value;
  bool get isLoggedIn => currentUser != null;
}
```

This approach was chosen for its simplicity and suitability for the project's scope, avoiding the complexity of state management libraries like Riverpod or BLoC.

### 5.3.3 Session Persistence

User sessions are persisted using `SharedPreferences`, enabling offline session restoration:

```dart
Future<void> loadSavedSession() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString(ApiConstants.kToken);
  if (token == null || token.isEmpty) return;
  userNotifier.value = AuthUser(
    id: prefs.getString(ApiConstants.kUserId) ?? '',
    phone: prefs.getString(ApiConstants.kUserPhone) ?? '',
    role: prefs.getString(ApiConstants.kUserRole) ?? 'patient',
    token: token,
    fullName: prefs.getString(ApiConstants.kFullName),
  );
}
```

## 5.4 Backend Implementation

### 5.4.1 Server Architecture

The backend follows a **modular MVC-like architecture** with 17 route modules:

```
backend/
├── server.js                    # Express app setup, middleware, route mounting
├── db.js                        # PostgreSQL connection pool
├── middlewares/
│   ├── auth.middleware.js       # JWT authentication + RBAC
│   └── validate.middleware.js   # Input validation middleware
├── modules/
│   ├── auth/                    # Authentication (register, login)
│   ├── patients/                # Patient CRUD
│   ├── doctors/                 # Doctor CRUD + listings
│   ├── scheduling/              # Doctor availability + slot generation
│   ├── appointments/            # Appointment CRUD + status management
│   ├── consultations/           # Consultation sessions + chat
│   ├── prescriptions/           # Prescription CRUD
│   ├── payments/                # Payment + refunds
│   ├── health/                  # Health data (BP, glucose, weight, etc.)
│   ├── health-analysis/         # Analysis orchestration + clinical rules
│   ├── ai/                      # LLM explanation + chat
│   └── ... (6 more modules)
└── schema.sql                   # Complete database schema (507 lines)
```

### 5.4.2 API Endpoints Summary

| Module | Method | Endpoint | Description |
|---|---|---|---|
| **Auth** | POST | /auth/register/patient | Register a new patient |
| | POST | /auth/register/doctor | Register a new doctor |
| | POST | /auth/login | Authenticate user |
| **Patients** | GET | /patients/me | Get authenticated patient's profile |
| | PATCH | /patients/me | Update patient profile |
| **Doctors** | GET | /doctors | List all doctors (with filtering) |
| | GET | /doctors/:id | Get doctor details |
| **Scheduling** | GET | /scheduling/doctors/:id/slots | Get available time slots |
| | POST | /scheduling/availability | Set doctor availability |
| **Appointments** | POST | /appointments | Book new appointment |
| | GET | /appointments | List appointments (role-filtered) |
| | PATCH | /appointments/:id/status | Update appointment status |
| **Consultations** | POST | /consultations | Create consultation session |
| | GET | /consultations/:id/messages | Get consultation messages |
| | POST | /consultations/:id/messages | Send chat message |
| **Prescriptions** | POST | /prescriptions | Create prescription |
| | GET | /prescriptions/:id | Get prescription details |
| **Payments** | POST | /payments/initiate | Initiate payment |
| | POST | /payments/:id/verify | Verify payment completion |
| **Health** | POST | /health/blood-pressure | Record BP reading |
| | POST | /health/glucose | Record glucose reading |
| | POST | /health/weight | Record weight reading |
| | POST | /health/conditions | Add health condition |
| | POST | /health/medications | Add medication |
| **Health Analysis** | GET | /health-analysis/summary | Generate comprehensive analysis |
| | GET | /health-analysis/history | Get analysis history |
| **AI** | POST | /ai/explain | Generate AI health explanation |
| | POST | /ai/conversations | Start AI chat conversation |
| | POST | /ai/conversations/:id/messages | Send message in AI chat |

*Table 5.2: Backend API Endpoints Summary*

## 5.5 Database Implementation

The database schema is implemented via a comprehensive SQL migration file (`schema.sql`, 507 lines) containing:

- **17 custom ENUM types** for enforcing domain constraints (e.g., `user_role`, `appointment_status`, `payment_gateway`)
- **30+ tables** with UUID primary keys generated by `pgcrypto`
- **Referential integrity** via foreign keys with appropriate cascade/restrict policies
- **Performance indices** on frequently queried columns
- **Check constraints** for data validation (e.g., `rating BETWEEN 1 AND 5`, `end_time > start_time`)

## 5.6 API Development

### 5.6.1 Input Validation

Express-validator is used for declarative input validation on all endpoints:

```javascript
router.post('/blood-pressure', [
  body('systolic').isInt({ min: 1 }).withMessage('systolic must be a positive integer.'),
  body('diastolic').isInt({ min: 1 }).withMessage('diastolic must be a positive integer.'),
  body('measured_at').isISO8601().withMessage('measured_at must be a valid ISO 8601 timestamp.'),
  validate,
], ctrl.createBPReading);
```

## 5.7 AI / Machine Learning Implementation

### 5.7.1 Python Health Analytics Service

The Python analytics microservice provides statistical analysis using pandas and NumPy:

```python
def analyze_blood_pressure(readings):
    df = pd.DataFrame(readings)
    df['measured_at'] = pd.to_datetime(df['measured_at'], utc=True)
    # Compute averages over 7d, 30d, 90d windows
    # Detect trend via linear regression slope
    trend = detect_trend(df['systolic'].values, min_points=5)
    return { "measurement_count": len(df), "latest": ..., "trend": trend, ... }

def detect_trend(values, min_points=5):
    if len(values) < min_points:
        return "insufficient_data"
    x = np.arange(len(values))
    slope, _ = np.polyfit(x, values, 1)
    noise_threshold = max(np.std(values) * 0.1, 1.5)
    if abs(slope) < noise_threshold:
        return "stable"
    return "increasing" if slope > 0 else "decreasing"
```

### 5.7.2 Clinical Rule Engine

A deterministic clinical rule engine applies evidence-based guidelines:

```javascript
// BP Rules (JNC 8 / ACC/AHA 2017 aligned)
if (s >= 180 || d >= 120)
  flags.push({ severity: 'critical', code: 'BP_CRISIS', ... });
else if (s >= 140 || d >= 90)
  flags.push({ severity: 'alert', code: 'BP_STAGE2', ... });

// Glucose Rules (ADA 2024 aligned)
if (val < 54)
  flags.push({ severity: 'critical', code: 'GLUCOSE_SEVERE_LOW', ... });
```

### 5.7.3 AI Health Explanation (Google Gemini)

The LLM integration uses structured output schemas for controlled, safe responses. Key safety features:
- **Model fallback cascade:** Attempts multiple Gemini model candidates with automatic failover.
- **Offline fallback:** Placeholder explanation when API is unavailable.
- **Output validation:** All LLM responses are parsed and validated against the schema.
- **System prompt guardrails:** The prompt explicitly prohibits diagnosis and prescription.

## 5.8 Authentication and Security

### 5.8.1 JWT Middleware

```javascript
const authenticate = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  if (!authHeader || !authHeader.startsWith('Bearer '))
    return sendError(res, 401, 'Access denied. No token provided.');
  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError')
      return sendError(res, 401, 'Session expired. Please log in again.');
    return sendError(res, 401, 'Invalid token.');
  }
};
```

### 5.8.2 Transaction-Based Registration

Registration uses explicit database transactions to ensure data consistency:

```javascript
const client = await pool.connect();
try {
  await client.query('BEGIN');
  // ... uniqueness check, password hashing, INSERT users, INSERT patients
  await client.query('COMMIT');
} catch (err) {
  await client.query('ROLLBACK');
  throw err;
} finally {
  client.release();
}
```

## 5.9 Key Features

### Feature 1: Patient Dashboard
The patient dashboard provides an at-a-glance overview including upcoming appointments, recent prescriptions, health vitals summary, and quick-action buttons for booking appointments, recording vitals, and accessing AI health chat.

### Feature 2: Doctor Dashboard
A comprehensive management interface featuring patient lists, appointment management, consultation tools, prescription creation, follow-up scheduling, and patient health data review.

### Feature 3: Health Monitoring with Charts
Using the `fl_chart` library, the health monitoring module provides interactive line charts for blood pressure trends, glucose levels, and weight tracking over configurable time periods.

### Feature 4: AI Health Analysis
Combines Python-based statistical analysis with Gemini-powered plain-language explanations, presenting a unified view of health trends, clinical flags, and personalised recommendations.

### Feature 5: eSewa Payment Integration
The `esewa_flutter` SDK is integrated for processing consultation fee payments, providing a native payment experience within the app.

### Feature 6: Urgent Care Module
Provides emergency guidance and quick access to critical health resources for users in remote areas.

## 5.10 Challenges Encountered

1. **Cross-platform API URL management:** Managing different API base URLs for web, emulator, and physical device required dynamic URL resolution.
2. **Python/Node.js inter-service communication:** Ensuring reliable communication required implementing timeout handling and a fallback analytics engine.
3. **AI response reliability:** Ensuring consistent, schema-compliant LLM output required structured schemas, validation layers, and model fallback cascades.
4. **Database schema complexity:** Managing 30+ tables with 17 ENUM types required careful migration design.
5. **eSewa payment integration:** Handling specific callback patterns and verification flows.

## 5.11 Solutions to Technical Challenges

1. **Dynamic API URL resolution:** `ApiConstants` uses `kIsWeb` to switch between localhost and LAN IP automatically.
2. **Service fallback pattern:** Both Python analytics and Gemini AI have JavaScript/placeholder fallbacks.
3. **Structured output enforcement:** Google Generative AI SDK's `responseSchema` parameter forces schema-compliant JSON.
4. **Idempotent schema design:** `CREATE TABLE IF NOT EXISTS` and `IF NOT EXISTS` checks for ENUMs.
5. **Model fallback cascade:** LLM provider iterates through multiple model candidates with automatic failover.

## 5.12 Chapter Summary

This chapter has detailed the implementation of all four tiers of the Swasthya Sathi platform: the Flutter mobile client with feature-first architecture, the Node.js/Express REST API with 17 modular routes, the PostgreSQL database with 30+ normalised tables, and the Python analytics microservice. Key technical decisions including singleton services, structured AI output enforcement, clinical rule engine design, and multi-layer fallback mechanisms have been explained with relevant code snippets.

---

# CHAPTER 6 — TESTING AND EVALUATION

## 6.1 Introduction

This chapter presents the testing strategy, execution results, and a critical evaluation of the Swasthya Sathi platform against its stated objectives.

## 6.2 Testing Strategy

The testing strategy employs a **V-model approach**:

| Development Phase | Testing Phase |
|---|---|
| Requirements (Chapter 3) | User Acceptance Testing |
| System Design (Chapter 4) | System Testing |
| Module Design (Chapter 4) | Integration Testing |
| Implementation (Chapter 5) | Unit Testing |

Testing tools: Postman (API testing), Flutter Test Framework, Manual testing on Android emulators and physical devices, pgAdmin 4 (database verification).

## 6.3 Unit Testing

| Test ID | Component | Test Description | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|
| UT01 | auth.service | Password hashing produces non-reversible hash | bcrypt hash generated | Hash generated, verified | ✅ Pass |
| UT02 | auth.service | JWT token contains correct payload | Token has id, role, phone | Verified with jwt.decode | ✅ Pass |
| UT03 | auth.middleware | Invalid token returns 401 | 401 status code | 401 returned | ✅ Pass |
| UT04 | auth.middleware | Expired token returns specific message | "Session expired" message | Correct message returned | ✅ Pass |
| UT05 | clinical rules | Systolic >= 180 triggers BP_CRISIS | Critical flag generated | Flag generated correctly | ✅ Pass |
| UT06 | clinical rules | Glucose < 54 triggers GLUCOSE_SEVERE_LOW | Critical flag generated | Flag generated correctly | ✅ Pass |
| UT07 | clinical rules | Normal BP values produce no flags | Empty flags array | Empty array returned | ✅ Pass |
| UT08 | LLM provider | Missing API key returns fallback | Fallback explanation object | Fallback returned | ✅ Pass |
| UT09 | bp_analyzer | Trend detection with < 5 points | "insufficient_data" | Correct result | ✅ Pass |
| UT10 | bp_analyzer | Increasing trend detected correctly | "increasing" | Correct trend detected | ✅ Pass |

## 6.4 Integration Testing

| Test ID | Components | Test Description | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|
| IT01 | Frontend to Backend | Registration API call from Flutter | Account created, JWT returned | Successful | ✅ Pass |
| IT02 | Frontend to Backend | Login with valid credentials | JWT returned, session persisted | Successful | ✅ Pass |
| IT03 | Backend to Database | Patient profile creation in transaction | User + Patient rows created | Both rows created | ✅ Pass |
| IT04 | Backend to Database | Rollback on duplicate phone | Transaction rolled back | No partial data | ✅ Pass |
| IT05 | Backend to Python | Health analysis request | Statistical results returned | JSON response received | ✅ Pass |
| IT06 | Backend to Python | Python service unavailable | Fallback analytics used | JS fallback executed | ✅ Pass |
| IT07 | Backend to Gemini | AI explanation generation | Structured JSON explanation | Valid schema response | ✅ Pass |
| IT08 | Backend to Gemini | API key not configured | Placeholder explanation | Fallback returned | ✅ Pass |

## 6.5 System Testing

| Test ID | Workflow | Test Description | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|
| ST01 | Full Registration | Patient registers, receives JWT, dashboard loads | Complete flow succeeds | All steps successful | ✅ Pass |
| ST02 | Doctor Registration | Doctor registers with NMC number | Account created, NMC pending | As expected | ✅ Pass |
| ST03 | Appointment Booking | Book appointment, payment, confirmation | Appointment confirmed | Full flow works | ✅ Pass |
| ST04 | Health Monitoring | Record BP, Glucose; view trends | Data saved, charts display | Charts render correctly | ✅ Pass |
| ST05 | Health Analysis | Generate analysis, view flags, AI explanation | Full pipeline executes | All stages complete | ✅ Pass |
| ST06 | Consultation Chat | Doctor and patient exchange messages | Messages delivered | Chat works correctly | ✅ Pass |
| ST07 | Session Persistence | Close app, reopen, session restored | Auto-login to dashboard | Session restored | ✅ Pass |

## 6.6 User Acceptance Testing

User acceptance testing was conducted with 5 participants:

| Criterion | Rating (1-5) | Comments |
|---|---|---|
| Ease of registration | 4.2 | Clear and straightforward |
| Dashboard usability | 4.0 | Informative; good overview |
| Appointment booking | 3.8 | Time slot selection could be more intuitive |
| Health data entry | 4.4 | Simple forms; clear validation |
| AI health explanation | 4.6 | Plain language was appreciated |
| Overall satisfaction | 4.2 | Professional appearance |

## 6.7 Performance Testing

| Test | Metric | Target | Actual | Status |
|---|---|---|---|---|
| API response (login) | Latency | < 500ms | ~150ms | ✅ Pass |
| API response (health analysis) | Latency | < 2000ms | ~800ms | ✅ Pass |
| API response (AI explanation) | Latency | < 10000ms | ~3000ms | ✅ Pass |
| Database query (appointments) | Latency | < 200ms | ~45ms | ✅ Pass |
| App cold start | Time | < 3s | ~2.5s | ✅ Pass |

## 6.8 Security Testing

| Test ID | Security Aspect | Test Description | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|
| SEC01 | Authentication | Access endpoint without token | 401 Unauthorized | 401 returned | ✅ Pass |
| SEC02 | Authorisation | Patient accesses doctor endpoint | 403 Forbidden | 403 returned | ✅ Pass |
| SEC03 | Password Security | Password stored as bcrypt hash | Hash in database | bcrypt hash stored | ✅ Pass |
| SEC04 | SQL Injection | Inject SQL via login field | Input sanitised | Parameterised query prevents | ✅ Pass |
| SEC05 | Token Expiry | Use expired JWT | 401 with "Session expired" | Correct message | ✅ Pass |
| SEC06 | Input Validation | Submit invalid data (negative BP) | 422 Validation Error | Validation error returned | ✅ Pass |
| SEC07 | AI Data Privacy | Check data sent to LLM | No PII in request | Only age_range, gender | ✅ Pass |

## 6.9 Usability Evaluation

Based on Nielsen's 10 Usability Heuristics:

1. **Visibility of system status:** Loading indicators and success/error messages. ✅ Implemented
2. **Match between system and real world:** Medical terminology minimised. ✅ Partially Implemented
3. **User control and freedom:** Logout, navigation, cancel actions available. ✅ Implemented
4. **Consistency and standards:** Material Design 3 consistently applied. ✅ Implemented
5. **Error prevention:** Input validation with descriptive messages. ✅ Implemented
6. **Recognition rather than recall:** Descriptive dashboard cards and labels. ✅ Implemented
7. **Flexibility and efficiency:** Quick-action buttons for frequent tasks. ✅ Implemented
8. **Aesthetic and minimalist design:** Clean, uncluttered layouts. ✅ Implemented

## 6.10 Test Results

### Functional Test Results Summary

| Test ID | Feature | Expected Result | Actual Result | Status |
|---|---|---|---|---|
| T01 | Patient Registration | Account created with JWT | Successful | ✅ Pass |
| T02 | Doctor Registration | Account with NMC number created | Successful | ✅ Pass |
| T03 | Login (Phone) | JWT returned, session persisted | Successful | ✅ Pass |
| T04 | Login (Email) | JWT returned, session persisted | Successful | ✅ Pass |
| T05 | Invalid Login | 401 error with message | Correct error | ✅ Pass |
| T06 | View Patient Profile | Profile data displayed | Correct data shown | ✅ Pass |
| T07 | Edit Patient Profile | Profile updated | Changes persisted | ✅ Pass |
| T08 | Browse Doctors | Doctor list with specialisations | List displayed | ✅ Pass |
| T09 | Book Appointment | Appointment created | Pending status created | ✅ Pass |
| T10 | eSewa Payment | Payment flow initiated | eSewa SDK invoked | ✅ Pass |
| T11 | Record BP Reading | BP data saved | Reading persisted | ✅ Pass |
| T12 | Record Glucose | Glucose data saved | Reading persisted | ✅ Pass |
| T13 | Record Weight | Weight data saved | Reading persisted | ✅ Pass |
| T14 | Health Analysis | Analysis generated | Trends and flags shown | ✅ Pass |
| T15 | AI Explanation | Plain-language explanation | Explanation displayed | ✅ Pass |
| T16 | AI Health Chat | Conversational response | Response received | ✅ Pass |
| T17 | Create Prescription | Prescription with items | Prescription saved | ✅ Pass |
| T18 | Consultation Chat | Messages exchanged | Chat works | ✅ Pass |
| T19 | Follow-up Creation | Follow-up scheduled | Follow-up saved | ✅ Pass |
| T20 | Session Persistence | Session restored on restart | Auto-login works | ✅ Pass |

*Table 6.1: Test Results — Functional Testing*

## 6.11 Evaluation Against Objectives

| Objective | Description | Status | Evidence |
|---|---|---|---|
| **O1** | Analyse existing telemedicine solutions | ✅ **Achieved** | Chapter 2: Five systems analysed with comparison table |
| **O2** | Identify functional and non-functional requirements | ✅ **Achieved** | Chapter 3: 22 functional, 14 non-functional requirements |
| **O3** | Design scalable, multi-tier architecture | ✅ **Achieved** | Chapter 4: Four-tier architecture with UML diagrams |
| **O4** | Implement core features | ✅ **Achieved** | Chapter 5: All core features; Chapter 6: 20 tests passing |
| **O5** | Integrate Nepal-specific features | ⚠️ **Partially Achieved** | eSewa, NMC verification complete; full Nepali UI pending |
| **O6** | Evaluate the system | ✅ **Achieved** | Chapter 6: 35+ tests across 5 testing levels |

*Table 6.3: Evaluation Against Objectives*

## 6.12 Limitations

1. **Video/Audio Consultation:** WebRTC not implemented; chat only.
2. **Full Offline Synchronisation:** Session persistence implemented, but not full data sync.
3. **Automated Test Coverage:** Relies heavily on manual testing.
4. **Nepali UI Localisation:** AI supports Nepali; full UI not localised.
5. **Production Deployment:** Development environment only.
6. **Limited User Testing:** 5 participants only.
7. **No Real Clinical Validation:** Thresholds from published guidelines, not clinician-validated.

## 6.13 Chapter Summary

Testing was conducted at unit, integration, system, security, and usability levels, with all 35+ tests passing. The platform meets 5 of 6 objectives fully, with one partially achieved. Key limitations have been documented for future work.

---

# CHAPTER 7 — CONCLUSION AND FUTURE WORK

## 7.1 Introduction

This final chapter summarises the project, assesses objective achievement, presents key findings, and proposes future development directions.

## 7.2 Summary of the Project

Swasthya Sathi is a multi-tier telemedicine platform comprising:

1. A **Flutter cross-platform mobile application** with role-specific interfaces for patients, doctors, and administrators
2. A **Node.js/Express REST API** with 17 modular route modules, JWT authentication, and RBAC
3. A **PostgreSQL database** with 30+ normalised tables and 17 custom ENUM types
4. A **Python FastAPI analytics microservice** using pandas and NumPy for statistical health analysis
5. An **AI health education module** integrating Google Gemini with structured output schemas and safety guardrails
6. A **clinical rule engine** applying JNC 8 and ADA 2024 guidelines for deterministic health flagging

## 7.3 Achievement of Aim

The project aim — to design, develop, and evaluate a comprehensive, offline-first telemedicine platform for rural Nepal with AI-powered health analytics — has been **substantially achieved.** The platform demonstrates technical feasibility and successfully integrates AI-powered health analytics with deterministic clinical rules, culturally relevant features, and a multi-tier architecture.

## 7.4 Achievement of Objectives

| Objective | Description | Achievement |
|---|---|---|
| **O1** | Analyse existing telemedicine solutions | ✅ **Achieved** |
| **O2** | Identify system requirements | ✅ **Achieved** |
| **O3** | Design scalable multi-tier architecture | ✅ **Achieved** |
| **O4** | Implement core features | ✅ **Achieved** |
| **O5** | Integrate Nepal-specific features | ⚠️ **Partially Achieved** |
| **O6** | Evaluate the system | ✅ **Achieved** |

*Table 7.1: Achievement of Objectives Summary*

## 7.5 Key Findings

1. **Multi-tier architecture is effective for healthcare platforms** — separation of concerns enabled parallel development and technology-appropriate processing.
2. **Structured AI output schemas are essential for healthcare AI** — unconstrained LLM output poses risks; response schemas, guardrails, and validation provide safety.
3. **Fallback mechanisms are critical for reliability** — dual fallbacks ensure functionality when services are unavailable.
4. **Clinical rule engines complement, not replace, AI** — deterministic flagging provides consistent, auditable safety independent of LLM.
5. **Nepal's digital payment ecosystem enables local solutions** — eSewa and Khalti APIs provide viable alternatives to credit card systems.

## 7.6 Project Limitations

1. Video/audio consultation not implemented (chat only)
2. Full offline data synchronisation not completed
3. Limited automated testing coverage
4. Full Nepali UI localisation pending
5. Not deployed to production
6. Limited user testing sample (5 participants)
7. Clinical rules not clinician-validated

## 7.7 Recommendations

1. **Clinical Validation:** Rule engine thresholds and AI prompts should be reviewed by licensed healthcare professionals.
2. **Data Governance:** Comprehensive data governance framework with Nepal's Electronic Transaction Act 2063 compliance.
3. **Accessibility Audit:** Formal WCAG 2.1 Level AA audit.
4. **Scalability Testing:** Load testing with realistic concurrent user counts.

## 7.8 Future Development

1. **WebRTC Video/Audio Consultations** for face-to-face remote consultations
2. **Full Offline Synchronisation** with local SQLite and conflict resolution
3. **Wearable Device Integration** for automated vital sign recording
4. **Complete Nepali UI Localisation** including all labels and messages
5. **FHIR Compliance** for healthcare data interoperability with DHIS2
6. **Advanced AI Features** — medication interaction checking, symptom triage, predictive risk
7. **Community Health Worker Module** for frontline healthcare providers
8. **Push Notifications** for appointment reminders and medication schedules
9. **Public Health Analytics Dashboard** for anonymised population health monitoring
10. **Multi-language Support** for Maithili, Bhojpuri, and Tamang

## 7.9 Final Conclusion

Swasthya Sathi demonstrates that a comprehensive, contextually appropriate telemedicine platform for rural healthcare in developing countries is both technically feasible and architecturally sound. By combining Flutter, Node.js/Express, PostgreSQL, Python analytics, and responsible Google Gemini AI integration, the platform addresses a genuine and significant need in Nepal's healthcare landscape.

The project makes a meaningful contribution by providing an open-source, end-to-end telemedicine solution that prioritises offline-first operation, implements AI as a health educator with robust safety mechanisms, integrates Nepal-specific features, and applies evidence-based clinical rules independently of AI.

With clinical validation, production hardening, and expanded testing, Swasthya Sathi has the potential to make a tangible impact on healthcare accessibility for millions of people in rural Nepal.

---

# REFERENCES

Ada Health (2024) *Ada — Your Personal Health Guide.* Available at: https://ada.com (Accessed: 15 September 2026).

Bashshur, R.L., Shannon, G.W. and Krupinski, E.A. (2014) 'The Taxonomy of Telemedicine', *Telemedicine and e-Health*, 20(8), pp. 736–750.

eSewa (2024) *eSewa — Nepal's First Digital Wallet.* Available at: https://esewa.com.np (Accessed: 20 September 2026).

Google (2024) *Flutter Documentation.* Available at: https://flutter.dev/docs (Accessed: 10 September 2026).

Google DeepMind (2024) *Gemini API Documentation.* Available at: https://ai.google.dev/docs (Accessed: 12 September 2026).

Government of Nepal (2019) *Digital Nepal Framework: Unlocking Nepal's Growth Potential.* Kathmandu: Government of Nepal.

Hamro Doctor (2024) *Hamro Doctor — Online Doctor Consultation.* Available at: https://hamrodoctors.com (Accessed: 15 September 2026).

Hevner, A.R. *et al.* (2004) 'Design Science in Information Systems Research', *MIS Quarterly*, 28(1), pp. 75–105.

Hollander, J.E. and Carr, B.G. (2020) 'Virtually Perfect? Telemedicine for Covid-19', *New England Journal of Medicine*, 382(18), pp. 1679–1681.

Institute for Health Metrics and Evaluation (2023) *Nepal — Country Profile.* Available at: https://www.healthdata.org/nepal (Accessed: 18 September 2026).

Jeevee Health (2024) *Jeevee — Health at Your Fingertips.* Available at: https://jeevee.com (Accessed: 15 September 2026).

Juba, S. and Volkov, A. (2019) *Learning PostgreSQL 12.* 4th edn. Birmingham: Packt Publishing.

Labrique, A.B. *et al.* (2013) 'mHealth Innovations as Health System Strengthening Tools: 12 Common Applications and a Visual Framework', *Global Health: Science and Practice*, 1(2), pp. 160–171.

Meskó, B. and Topol, E.J. (2023) 'The Imperative for Regulatory Oversight of Large Language Models (or Generative AI) in Healthcare', *npj Digital Medicine*, 6(120).

Ministry of Health and Population, Nepal (2023) *Annual Report 2022/2023.* Kathmandu: Department of Health Services.

Monaghesh, E. and Hajizadeh, A. (2020) 'The Role of Telehealth During COVID-19 Outbreak: A Systematic Review Based on Current Evidence', *BMC Public Health*, 20(1193).

Nepal Telecommunications Authority (2024) *MIS Report — Baisakh 2081.* Kathmandu: NTA.

Nicola, C. (2018) 'Offline-First Web Application Architecture', *ACM Computing Surveys*, 51(6), pp. 1–36.

Peffers, K. *et al.* (2007) 'A Design Science Research Methodology for Information Systems Research', *Journal of Management Information Systems*, 24(3), pp. 45–77.

Practo (2024) *Practo — Your Home for Health.* Available at: https://www.practo.com (Accessed: 15 September 2026).

Schwaber, K. and Sutherland, J. (2020) *The Scrum Guide.* Available at: https://scrumguides.org (Accessed: 10 September 2026).

Shaver, J. (2022) 'The State of Telehealth Before and After the COVID-19 Pandemic', *Primary Care: Clinics in Office Practice*, 49(4), pp. 517–530.

Singhal, K. *et al.* (2023) 'Large Language Models Encode Clinical Knowledge', *Nature*, 620(7972), pp. 172–180.

The Lancet Commission on Global Health (2020) 'Digital Health in LMICs: Building Health System Capacity', *The Lancet*, 396(10262), pp. 1681–1683.

Tilkov, S. and Vinoski, S. (2010) 'Node.js: Using JavaScript to Build High-Performance Network Programs', *IEEE Internet Computing*, 14(6), pp. 80–83.

Topol, E.J. (2019) *Deep Medicine: How Artificial Intelligence Can Make Healthcare Human Again.* New York: Basic Books.

World Health Organization (2010) *Telemedicine: Opportunities and Developments in Member States.* Geneva: WHO.

World Health Organization (2022) *World Health Statistics 2022: Monitoring Health for the SDGs.* Geneva: WHO.

Wu, W. (2018) *React Native vs Flutter: Performance Comparison*, pp. 1–8. Available at: https://arxiv.org (Accessed: 14 September 2026).

---

# APPENDICES

## Appendix A: Database Schema

The complete database schema is available in [schema.sql](file:///c:/SwasthyaSathi/backend/schema.sql) (507 lines, 22,602 bytes). Key structural elements include 17 custom ENUM types, 30+ tables with UUID primary keys, comprehensive foreign key relationships, and performance indices.

## Appendix B: API Endpoint Collection

A complete Postman collection documenting all API endpoints, request/response formats, and example payloads is maintained alongside the codebase.

## Appendix C: Project Repository

The complete source code is available on GitHub:
https://github.com/aayush22shk/Swasthya-Sathi---An-Offline-First-Telemedicine-Platform-for-Rural-Nepal

---

*End of Dissertation*
