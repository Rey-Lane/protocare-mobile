# Task: Add Image Uploading for ProtocolAction Entity

## Overview
Add the ability to upload and manage images for `ProtocolAction` entities (actions within a protocol). Currently, images can be attached to `checkin`, `protocol`, and `action` entities, but NOT to `protocol_action` entities.

## Context
- `ProtocolAction` represents an action scheduled within a specific protocol (see `protocare/models.py:134-148`)
- `CheckIn` is linked to a `ProtocolAction` via `protocol_action_id`
- Images are stored via `ImageAttachment` model with polymorphic attachment via `attachable_type` and `attachable_id`
- Current `AttachableType` enum values: `CHECKIN`, `PROTOCOL`, `ACTION`

## Required Changes

### 1. Update `protocare/shared/enums.py`
Add `PROTOCOL_ACTION` to `AttachableType` enum:
```python
class AttachableType(StrEnum):
    CHECKIN = auto()
    PROTOCOL = auto()
    ACTION = auto()
    PROTOCOL_ACTION = auto()  # ADD THIS
```

### 2. Update `protocare/models.py`
Add relationship from `ProtocolAction` to `ImageAttachment`:
- Add `images: list['ImageAttachment']` relationship to `ProtocolAction` model (similar to how other entities have it)

### 3. Update `protocare/views/images.py`
Add two new endpoints following the existing pattern:

**Upload endpoint:**
- Path: `POST /protocol-actions/{protocol_action_id}`
- Follow pattern of `upload_checkin_image` (lines 21-48)
- Use `entity_type='protocol_action'`

**Get endpoint:**
- Path: `GET /protocol-actions/{protocol_action_id}`
- Follow pattern of `get_checkin_image` (lines 111-136)
- Use `entity_type='protocol_action'`

### 4. Update `protocare/services/image_service.py`
Update the docstring in `upload_image` method (line 78) to include `protocol_action`:
```python
entity_type: Type of entity ('checkin', 'protocol', 'action', 'protocol_action')
```

### 5. Add/Update Tests in `tests/test_images/`

**Update `tests/test_images/conftest.py`:**
- Add `db_protocol_action_with_image` fixture (similar to `db_protocol_with_image`)
- Add `db_image_for_protocol_action` fixture (similar to `db_image_for_protocol`)

**Update `tests/test_images/test_images.py`:**
- Add `('protocol-actions', 'db_protocol_action_with_image')` to all parameterized test lists:
  - `test_upload_image_success`
  - `test_upload_image_already_exists`
  - `test_upload_image_without_auth`
  - `test_get_image_success` (also needs image fixture)
  - `test_get_image_not_found`
  - `test_get_image_without_auth`

## Files to Modify
1. `protocare/shared/enums.py` - Add enum value
2. `protocare/models.py` - Add relationship
3. `protocare/views/images.py` - Add endpoints
4. `protocare/services/image_service.py` - Update docstring
5. `tests/test_images/conftest.py` - Add fixtures
6. `tests/test_images/test_images.py` - Add test cases

## Verification
After implementation, run tests:
```bash
pytest tests/test_images/ -v
```

## Notes
- Follow existing code patterns exactly - the image upload system is already well-structured
- The entity type string should be `'protocol_action'` (snake_case) for the service layer
- The URL path should be `/protocol-actions/` (kebab-case) for REST consistency
- Each entity can only have ONE image in the current MVP (enforced in `image_service.py` line 95-105)
