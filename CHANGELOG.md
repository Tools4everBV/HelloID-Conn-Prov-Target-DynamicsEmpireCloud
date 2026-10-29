# Change Log

All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com), and this project adheres to [Semantic Versioning](https://semver.org).

## [1.1.0] - 2026-10-23

### Added

- Paging support (`@odata.nextLink`) when retrieving users from Business Central
- GitHub workflows to verify the changelog and create releases

### Changed

- Renamed field `DisplayName` to `Fullname` in the field mapping and account data, to align with the AuthorizationBox connector
- Field mapping is now only mapped for the `Create` action
- Audit log on correlation now shows the `UserSecurityID` instead of the full account reference object
- README: updated correlation configuration, requirements, connection settings, account reference and API endpoints

### Fixed

- Company name is now URL-encoded in the API request
- No longer fails when Business Central returns no users; the action now reports that no matching user was found
- Display name of the person is now shown in the "Multiple users found" error message
- Removed an unused access token request and the Graph-only `ConsistencyLevel` header
- Replaced `Write-Error` with an explicit `Success = $false` when no matching user is found

## [1.0.0] - 2026-07-24

This is the first official release of _HelloID-Conn-Prov-Target-DynamicsEmpireCloud_.

### Added

- Initial implementation of the DynamicsEmpireCloud target connector
- OAuth 2.0 client credentials authentication against the Microsoft Business Central cloud API
