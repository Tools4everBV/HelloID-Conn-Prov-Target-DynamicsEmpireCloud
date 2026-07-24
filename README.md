# HelloID-Conn-Prov-Target-DynamicsEmpireCloud

<!--
** for extra information about alert syntax please refer to [Alerts](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax#alerts)
-->

> [!IMPORTANT]
> This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements.

> [!NOTE]
> This connector is usually linked to the [HelloID-Conn-Prov-Target-Authorizationbox](https://github.com/Tools4everBV/HelloID-Conn-Prov-Target-Authorizationbox) connector, as the `UserSecurityID` is required there.

<p align="center">
  <img src="">
</p>

## Table of contents

- [HelloID-Conn-Prov-Target-DynamicsEmpireCloud](#helloid-conn-prov-target-dynamicsempirecloud)
  - [Table of contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Supported features](#supported-features)
  - [Getting started](#getting-started)
    - [HelloID Icon URL](#helloid-icon-url)
    - [Requirements](#requirements)
    - [Connection settings](#connection-settings)
    - [Correlation configuration](#correlation-configuration)
    - [Field mapping](#field-mapping)
    - [Account Reference](#account-reference)
  - [Remarks](#remarks)
  - [Development resources](#development-resources)
    - [API endpoints](#api-endpoints)
    - [API documentation](#api-documentation)
  - [Getting help](#getting-help)
  - [HelloID docs](#helloid-docs)

## Introduction

_HelloID-Conn-Prov-Target-DynamicsEmpireCloud_ is a _target_ connector. _DynamicsEmpireCloud_ provides a set of REST APIs that allow you to programmatically interact with its data. This connector connects to the Microsoft Business Central cloud API using OAuth 2.0 client credentials.

## Supported features

The following features are available:

| Feature                                   | Supported | Actions           | Remarks                      |
| ----------------------------------------- | --------- | ----------------- | ---------------------------- |
| **Account Lifecycle**                     | ✅        | Correlate | Correlation is mandatory. Users are provisioned through a license group  |
| **Permissions**                           | ❌        | -                 |                              |
| **Resources**                             | ❌        | -                 |                              |
| **Entitlement Import: Accounts**          | ❌        | -                 |                              |
| **Entitlement Import: Permissions**       | ❌        | -                 |                              |
| **Governance Reconciliation Resolutions** | ❌        | -                 |                              |

## Getting started

### HelloID Icon URL

URL of the icon used for the HelloID Provisioning target system.

```
https://raw.githubusercontent.com/Tools4everBV/HelloID-Conn-Prov-Target-DynamicsEmpireCloud/refs/heads/main/Icon.png
```

### Requirements

- An **Azure AD App Registration** with `client_credentials` grant and access to the Business Central API (`https://api.businesscentral.dynamics.com/.default`).
- The App Registration must be assigned as an **Authorized Client App** in Business Central and the service principal must have sufficient rights to read users.
- Linked usage with the **AuthorizationBox** connector.

### Connection settings

The following settings are required to connect to the API.

| Setting        | Description                                                  | Mandatory |
| -------------- | ------------------------------------------------------------ | --------- |
| TenantID       | The Azure AD Directory (tenant) ID                           | Yes       |
| AppId          | The Azure AD App Registration Application (client) ID        | Yes       |
| AppSecret      | The Azure AD App Registration Client Secret                  | Yes       |
| Environment    | The Business Central environment name (e.g. `Production`)    | Yes       |
| DefaultCompany | The Business Central company name used to scope API requests | Yes       |

### Correlation configuration

The correlation configuration is used to specify which properties will be used to match an existing account within _DynamicsEmpireCloud_ to a person in _HelloID_.

| Setting                   | Value                                                              |
| ------------------------- | ------------------------------------------------------------------ |
| Enable correlation        | `True`                                                             |
| Person correlation field  | `Mail` |
| Account correlation field | `contactEmail`                                                         |

> [!TIP]
> _For more information on correlation, please refer to our correlation [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems/correlation.html) pages_.

### Field mapping

The field mapping can be imported by using the _fieldMapping.json_ file.

### Account Reference

The account reference is populated with the properties `UserSecurityID`, `FullName`, and `UserName` from _DynamicsEmpireCloud_. It is advised not to change the reference after creation or correlation, as the `UserSecurityID` is required by the AuthorizationBox connector.

## Remarks

- Correlation is **mandatory** for this connector. The create action will return an error when no matching account is found in Business Central.
- This connector is usually linked to the AuthorizationBox connector, as `UserSecurityID` is required there.

### Correlation Based on Email Address
- **Email Address Correlation**: The connector relies on email addresses to correlate and match records between systems. Ensure that email addresses are accurately maintained and consistent across systems to avoid issues with data synchronization and matching.

## Development resources

### API endpoints

The following endpoints are used by the connector.

| Endpoint                                                      | Description                       |
| ------------------------------------------------------------- | --------------------------------- |
| `/api/microsoft/automation/v2.0/users?company={companyName}` | Retrieve all users for a company  |

### API documentation

Unofficial documentation on creating the app registration:
https://docs.cloudblue.com/cbc/21.0/Native-Integrations/Conifguring-Dynamics-Application.htm

## Getting help

> [!TIP]
> _For more information on how to configure a HelloID PowerShell connector, please refer to our [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems.html) pages_.

> [!TIP]
>  _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com)_.

## HelloID docs

The official HelloID documentation can be found at: https://docs.helloid.com/
