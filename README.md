# RMN Business Admin Dashboard

A comprehensive, secure, and responsive **Business Operations Dashboard** built with Flutter and Supabase. This internal web application is designed to centralize financial management, HR operations, and investor relations for a company, providing real-time insights and control.

![Dashboard View](https://your-link-to-screenshot-1.png)
*Home dashboard with financial overview.*

## ✨ Features

- **🔐 Secure Authentication:** Login and Sign-up with role-based access control, and only full controlled users can create new users.
- **📊 Real-Time Financial Dashboard:** View total Income, Expenses, and Net Cashflow at a glance.
- **👥 Employee Management (HR Module):**
  - Centralized employee directory with details (ID, Name, Department, Designation).
  - **Advanced Salary Disbursement System:** Calculate and process salaries Automatically, including:
    - Base Pay
    - Advances
    - Bonuses
    - Deductions (Late Fine, Absent Fine, Loan, Medical Insurance, PF)
- **💸 Granular Expense Tracking:**
  - Log every company expense with amount, category, description, and date.
  - Powerful search functionality to find entries quickly.
- **📈 Investor Management (IRM Module):** A dedicated space to manage and track investor information.

## 🖥️ Tech Stack

- **Frontend:** Flutter (Web)
- **Backend & Database:** Supabase (PostgreSQL), Hive Db
- **Authentication:** Supabase Auth

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (version 3.0.0 or above)
- A Supabase project ([Create one for free](https://supabase.com))