# Test Fixes Needed

## Document Model Changes
- Document now uses `uploaded_by` instead of `user`
- Need to update all factories and specs that reference `document.user`

## Common Test Failures
1. SearchController - using `user: user` instead of `uploaded_by: user`
2. Various specs expecting `document.user` instead of `document.uploaded_by`
3. Immo::Promo models need attribute type declarations for enums
4. Some models using incorrect associations or missing aliases

## Aliases Created
- Project: `alias_attribute :end_date, :expected_completion_date`
- Risk: `alias_attribute :risk_type, :category`
- Permit: `alias_attribute :start_date, :submitted_date` and `alias_attribute :end_date, :expiry_date`
- Certification: `alias_attribute :issuing_authority, :issuing_body`

## Seeds Status
- All fields are populated
- Some performance issues with large data creation
- All Immo::Promo models have been fixed to match database schema