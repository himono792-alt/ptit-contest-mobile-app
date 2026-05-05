-- =========================================================
-- PTIT Contest Management System - PostgreSQL Schema v02
-- =========================================================
-- Thay đổi so với v01 (2026-05-03):
--   + Thêm role BCN (Ban Chủ nhiệm khoa) — enum HOD
--   + Thêm bảng majors (ngành học) + cập nhật student_directory.major_id
--   + Thêm bảng department_heads (profile của BCN gắn theo khoa)
--   + Thêm workflow phê duyệt 2 cấp BTC↔BCN:
--       - workflow_approvals (BCN_QD1 phê duyệt đề xuất cuộc thi,
--                              BCN_QD2 phê duyệt kết quả chung cuộc)
--   + Thêm 2 trạng thái cho contest_status_enum:
--       - PROPOSED (BTC đã submit chờ BCN_QD1)
--       - REVISION_REQUESTED (BCN yêu cầu chỉnh sửa)
--   + Thêm cột proposed_by trong contests (BTC đề xuất)
--   + Thêm cột bcn_approval_status trong contest_results
--   + Indexes mới cho workflow_approvals + majors
--
-- Lưu ý sử dụng:
-- 1) Chạy trong database đã tạo sẵn, ví dụ:
--    CREATE DATABASE ptit_contest_db;
-- 2) Sau đó chạy file này trong database đó.
-- 3) Script này reset schema ptit_contest để tiện phát triển.
-- =========================================================

CREATE EXTENSION IF NOT EXISTS citext;

DROP SCHEMA IF EXISTS ptit_contest CASCADE;
CREATE SCHEMA ptit_contest;
SET search_path TO ptit_contest, public;

-- =========================================================
-- 1) ENUM TYPES
-- =========================================================

CREATE TYPE user_status_enum AS ENUM (
    'ACTIVE',
    'LOCKED',
    'DELETED'
);

CREATE TYPE role_code_enum AS ENUM (
    'ADMIN',
    'ORGANIZER',     -- BTC (Giảng viên/Ban tổ chức)
    'JUDGE',         -- Giám khảo (có thể trùng với organizer)
    'HOD',           -- BCN khoa (Head of Department)
    'STUDENT'
);

CREATE TYPE contest_status_enum AS ENUM (
    'DRAFT',                -- BTC đang soạn
    'PROPOSED',             -- BTC đã submit, chờ BCN_QD1 duyệt
    'REVISION_REQUESTED',   -- BCN yêu cầu chỉnh sửa, BTC đang fix
    'PUBLISHED',            -- BCN_QD1 đã duyệt, BTC đã publish
    'REG_OPEN',
    'REG_CLOSED',
    'ONGOING',
    'FINISHED',
    'CANCELLED'
);

CREATE TYPE entry_type_enum AS ENUM (
    'INDIVIDUAL',
    'TEAM'
);

CREATE TYPE registration_status_enum AS ENUM (
    'PENDING',
    'APPROVED',
    'REJECTED',
    'CANCELLED'
);

CREATE TYPE participant_status_enum AS ENUM (
    'REGISTERED',
    'CHECKED_IN',
    'SUBMITTED',
    'ELIMINATED',
    'COMPLETED'
);

CREATE TYPE delivery_mode_enum AS ENUM (
    'ONLINE',
    'OFFLINE',
    'HYBRID'
);

CREATE TYPE round_type_enum AS ENUM (
    'QUALIFIER',
    'PRELIMINARY',
    'SEMI_FINAL',
    'FINAL',
    'OTHER'
);

CREATE TYPE session_type_enum AS ENUM (
    'ONLINE',
    'OFFLINE'
);

CREATE TYPE submission_status_enum AS ENUM (
    'DRAFT',
    'SUBMITTED',
    'LOCKED',
    'LATE',
    'CANCELLED'
);

CREATE TYPE checkin_method_enum AS ENUM (
    'QR',
    'MANUAL',
    'ONLINE'
);

CREATE TYPE checkin_status_enum AS ENUM (
    'SUCCESS',
    'FAILED'
);

CREATE TYPE notification_scope_enum AS ENUM (
    'SYSTEM',
    'CONTEST'
);

CREATE TYPE question_status_enum AS ENUM (
    'OPEN',
    'ANSWERED',
    'CLOSED'
);

CREATE TYPE appeal_status_enum AS ENUM (
    'PENDING',
    'IN_REVIEW',
    'ACCEPTED',
    'REJECTED',
    'CLOSED'
);

-- ----- NEW: workflow approval enums -----
CREATE TYPE approval_target_enum AS ENUM (
    'CONTEST_PROPOSAL',  -- BTC đề xuất cuộc thi → BCN_QD1
    'CONTEST_RESULT'     -- BTC chốt kết quả → BCN_QD2
);

CREATE TYPE approval_step_enum AS ENUM (
    'BCN_QD1',           -- Quyết định phê duyệt đề xuất cuộc thi
    'BCN_QD2'            -- Quyết định phê duyệt kết quả chung cuộc
);

CREATE TYPE approval_status_enum AS ENUM (
    'PENDING',
    'APPROVED',
    'REJECTED',
    'REVISION_REQUESTED'
);

-- =========================================================
-- 2) COMMON FUNCTION: auto update updated_at
-- =========================================================

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- =========================================================
-- 3) USERS / ROLES
-- =========================================================

CREATE TABLE roles (
    role_id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    role_code        role_code_enum NOT NULL UNIQUE,
    role_name        VARCHAR(100) NOT NULL
);

CREATE TABLE app_users (
    user_id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email                CITEXT NOT NULL UNIQUE,
    password_hash        VARCHAR(255) NOT NULL,
    full_name            VARCHAR(150) NOT NULL,
    phone                VARCHAR(20),
    avatar_url           TEXT,
    status               user_status_enum NOT NULL DEFAULT 'ACTIVE',
    email_verified_at    TIMESTAMPTZ,
    last_login_at        TIMESTAMPTZ,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE user_roles (
    user_id              BIGINT NOT NULL REFERENCES app_users(user_id) ON DELETE CASCADE,
    role_id              BIGINT NOT NULL REFERENCES roles(role_id) ON DELETE RESTRICT,
    assigned_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, role_id)
);

CREATE TRIGGER trg_app_users_updated_at
BEFORE UPDATE ON app_users
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- Seed roles
INSERT INTO roles (role_code, role_name) VALUES
('ADMIN',     'Quản trị viên'),
('ORGANIZER', 'Ban tổ chức (Giảng viên)'),
('JUDGE',     'Ban giám khảo'),
('HOD',       'Ban Chủ nhiệm khoa'),
('STUDENT',   'Sinh viên');

-- =========================================================
-- 4) MASTER DATA: FACULTY / MAJOR / CLASS / DIRECTORY / PROFILE
-- =========================================================

CREATE TABLE faculties (
    faculty_id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    faculty_code        VARCHAR(30) NOT NULL UNIQUE,
    faculty_name        VARCHAR(150) NOT NULL
);

-- NEW: ngành học (thuộc khoa)
CREATE TABLE majors (
    major_id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    major_code          VARCHAR(30) NOT NULL UNIQUE,
    major_name          VARCHAR(150) NOT NULL,
    faculty_id          BIGINT REFERENCES faculties(faculty_id) ON DELETE SET NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE academic_classes (
    class_id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    class_code          VARCHAR(30) NOT NULL UNIQUE,
    class_name          VARCHAR(150) NOT NULL,
    faculty_id          BIGINT REFERENCES faculties(faculty_id) ON DELETE SET NULL,
    major_id            BIGINT REFERENCES majors(major_id) ON DELETE SET NULL
);

-- Danh mục sinh viên PTIT chuẩn do admin quản lý/import
CREATE TABLE student_directory (
    directory_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_code        VARCHAR(30) NOT NULL UNIQUE,      -- MSSV
    ptit_email          CITEXT NOT NULL UNIQUE,
    full_name           VARCHAR(150) NOT NULL,
    faculty_id          BIGINT REFERENCES faculties(faculty_id) ON DELETE SET NULL,
    major_id            BIGINT REFERENCES majors(major_id) ON DELETE SET NULL,
    class_id            BIGINT REFERENCES academic_classes(class_id) ON DELETE SET NULL,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    synced_at           TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE students (
    student_id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id             BIGINT NOT NULL UNIQUE REFERENCES app_users(user_id) ON DELETE CASCADE,
    directory_id        BIGINT NOT NULL UNIQUE REFERENCES student_directory(directory_id) ON DELETE RESTRICT,
    bio                 TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE organizers (
    organizer_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id             BIGINT NOT NULL UNIQUE REFERENCES app_users(user_id) ON DELETE CASCADE,
    organization_name   VARCHAR(150),
    faculty_id          BIGINT REFERENCES faculties(faculty_id) ON DELETE SET NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE judges (
    judge_id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id             BIGINT NOT NULL UNIQUE REFERENCES app_users(user_id) ON DELETE CASCADE,
    expertise           VARCHAR(255),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- NEW: profile của BCN (Ban Chủ nhiệm khoa)
-- Mỗi BCN gắn với 1 faculty, có thể là Trưởng khoa / Phó khoa
CREATE TABLE department_heads (
    dept_head_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id             BIGINT NOT NULL UNIQUE REFERENCES app_users(user_id) ON DELETE CASCADE,
    faculty_id          BIGINT NOT NULL REFERENCES faculties(faculty_id) ON DELETE RESTRICT,
    title               VARCHAR(100),                     -- "Trưởng khoa", "Phó khoa", ...
    is_primary_approver BOOLEAN NOT NULL DEFAULT FALSE,   -- người duyệt chính (mặc định)
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Mỗi khoa chỉ nên có 1 primary approver (tuỳ chính sách)
CREATE UNIQUE INDEX uq_dept_one_primary_approver
ON department_heads(faculty_id)
WHERE is_primary_approver = TRUE;

CREATE TRIGGER trg_students_updated_at
BEFORE UPDATE ON students
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_dept_heads_updated_at
BEFORE UPDATE ON department_heads
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- =========================================================
-- 5) CONTEST / ROUND / SESSION
-- =========================================================

CREATE TABLE contests (
    contest_id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    slug                      VARCHAR(120) NOT NULL UNIQUE,
    title                     VARCHAR(255) NOT NULL,
    description               TEXT,
    rules_text                TEXT,
    award_text                TEXT,
    banner_url                TEXT,
    delivery_mode             delivery_mode_enum NOT NULL,
    participation_mode        entry_type_enum NOT NULL,
    team_min_members          INT,
    team_max_members          INT,
    max_entries               INT,
    requires_submission       BOOLEAN NOT NULL DEFAULT FALSE,
    is_public                 BOOLEAN NOT NULL DEFAULT TRUE,
    registration_open_at      TIMESTAMPTZ,
    registration_close_at     TIMESTAMPTZ,
    start_at                  TIMESTAMPTZ NOT NULL,
    end_at                    TIMESTAMPTZ NOT NULL,
    location_text             VARCHAR(255),
    status                    contest_status_enum NOT NULL DEFAULT 'DRAFT',
    -- BTC đề xuất cuộc thi (NEW; thường = created_by lúc tạo)
    proposed_by               BIGINT REFERENCES app_users(user_id) ON DELETE SET NULL,
    -- Khoa chủ trì cuộc thi (NEW) — quyết định BCN nào duyệt
    host_faculty_id           BIGINT REFERENCES faculties(faculty_id) ON DELETE SET NULL,
    created_by                BIGINT NOT NULL REFERENCES app_users(user_id) ON DELETE RESTRICT,
    created_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_contest_time CHECK (end_at > start_at),
    CONSTRAINT chk_reg_time CHECK (
        registration_open_at IS NULL
        OR registration_close_at IS NULL
        OR registration_close_at >= registration_open_at
    ),
    CONSTRAINT chk_team_member_range CHECK (
        (participation_mode = 'INDIVIDUAL')
        OR
        (
            participation_mode = 'TEAM'
            AND team_min_members IS NOT NULL
            AND team_max_members IS NOT NULL
            AND team_min_members >= 1
            AND team_max_members >= team_min_members
        )
    )
);

CREATE TABLE contest_organizers (
    contest_id           BIGINT NOT NULL REFERENCES contests(contest_id) ON DELETE CASCADE,
    organizer_id         BIGINT NOT NULL REFERENCES organizers(organizer_id) ON DELETE CASCADE,
    assigned_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (contest_id, organizer_id)
);

CREATE TABLE contest_rounds (
    round_id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    contest_id                BIGINT NOT NULL REFERENCES contests(contest_id) ON DELETE CASCADE,
    round_no                  INT NOT NULL,
    round_name                VARCHAR(150) NOT NULL,
    round_type                round_type_enum NOT NULL DEFAULT 'OTHER',
    description               TEXT,
    start_at                  TIMESTAMPTZ NOT NULL,
    end_at                    TIMESTAMPTZ NOT NULL,
    submission_open_at        TIMESTAMPTZ,
    submission_close_at       TIMESTAMPTZ,
    judging_open_at           TIMESTAMPTZ,
    judging_close_at          TIMESTAMPTZ,
    is_elimination_round      BOOLEAN NOT NULL DEFAULT FALSE,
    created_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_round_per_contest UNIQUE (contest_id, round_no),
    CONSTRAINT chk_round_time CHECK (end_at > start_at)
);

CREATE TABLE contest_sessions (
    session_id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    contest_id            BIGINT NOT NULL REFERENCES contests(contest_id) ON DELETE CASCADE,
    round_id              BIGINT REFERENCES contest_rounds(round_id) ON DELETE SET NULL,
    session_name          VARCHAR(150) NOT NULL,
    session_type          session_type_enum NOT NULL,
    start_at              TIMESTAMPTZ NOT NULL,
    end_at                TIMESTAMPTZ NOT NULL,
    location_text         VARCHAR(255),
    room_text             VARCHAR(100),
    online_meeting_url    TEXT,
    checkin_open_at       TIMESTAMPTZ,
    checkin_close_at      TIMESTAMPTZ,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_session_time CHECK (end_at > start_at)
);

CREATE TABLE contest_judges (
    contest_id            BIGINT NOT NULL REFERENCES contests(contest_id) ON DELETE CASCADE,
    judge_id              BIGINT NOT NULL REFERENCES judges(judge_id) ON DELETE CASCADE,
    assigned_by           BIGINT REFERENCES app_users(user_id) ON DELETE SET NULL,
    assigned_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (contest_id, judge_id)
);

CREATE TRIGGER trg_contests_updated_at
BEFORE UPDATE ON contests
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- =========================================================
-- 6) TEAM / ENTRY / SESSION ASSIGNMENT
-- =========================================================

CREATE TABLE teams (
    team_id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    contest_id            BIGINT NOT NULL REFERENCES contests(contest_id) ON DELETE CASCADE,
    team_name             VARCHAR(150) NOT NULL,
    leader_student_id     BIGINT NOT NULL REFERENCES students(student_id) ON DELETE RESTRICT,
    status                VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (contest_id, team_name)
);

CREATE TABLE team_members (
    team_id               BIGINT NOT NULL REFERENCES teams(team_id) ON DELETE CASCADE,
    student_id            BIGINT NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    is_leader             BOOLEAN NOT NULL DEFAULT FALSE,
    joined_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (team_id, student_id)
);

CREATE UNIQUE INDEX uq_team_one_leader
ON team_members(team_id)
WHERE is_leader = TRUE;

-- Đơn vị dự thi: có thể là cá nhân hoặc đội
CREATE TABLE contest_entries (
    entry_id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    contest_id                BIGINT NOT NULL REFERENCES contests(contest_id) ON DELETE CASCADE,
    entry_type                entry_type_enum NOT NULL,
    student_id                BIGINT REFERENCES students(student_id) ON DELETE RESTRICT,
    team_id                   BIGINT REFERENCES teams(team_id) ON DELETE RESTRICT,
    anonymous_code            VARCHAR(50) UNIQUE,
    registration_status       registration_status_enum NOT NULL DEFAULT 'PENDING',
    participant_status        participant_status_enum NOT NULL DEFAULT 'REGISTERED',
    approved_by               BIGINT REFERENCES app_users(user_id) ON DELETE SET NULL,
    approved_at               TIMESTAMPTZ,
    registration_note         TEXT,
    created_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_entry_target CHECK (
        (
            entry_type = 'INDIVIDUAL'
            AND student_id IS NOT NULL
            AND team_id IS NULL
        )
        OR
        (
            entry_type = 'TEAM'
            AND team_id IS NOT NULL
            AND student_id IS NULL
        )
    )
);

CREATE UNIQUE INDEX uq_contest_individual_entry
ON contest_entries(contest_id, student_id)
WHERE student_id IS NOT NULL;

CREATE UNIQUE INDEX uq_contest_team_entry
ON contest_entries(contest_id, team_id)
WHERE team_id IS NOT NULL;

CREATE TABLE entry_status_logs (
    entry_status_log_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    entry_id                 BIGINT NOT NULL REFERENCES contest_entries(entry_id) ON DELETE CASCADE,
    old_status               participant_status_enum,
    new_status               participant_status_enum NOT NULL,
    changed_by               BIGINT REFERENCES app_users(user_id) ON DELETE SET NULL,
    note                     TEXT,
    changed_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Gán đơn vị dự thi vào ca thi/phòng thi
CREATE TABLE session_entries (
    session_id               BIGINT NOT NULL REFERENCES contest_sessions(session_id) ON DELETE CASCADE,
    entry_id                 BIGINT NOT NULL REFERENCES contest_entries(entry_id) ON DELETE CASCADE,
    seat_no                  VARCHAR(30),
    assigned_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (session_id, entry_id)
);

CREATE TRIGGER trg_teams_updated_at
BEFORE UPDATE ON teams
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_entries_updated_at
BEFORE UPDATE ON contest_entries
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- =========================================================
-- 7) SUBMISSION / FILE / VERSION
-- =========================================================

CREATE TABLE submissions (
    submission_id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    round_id                 BIGINT NOT NULL REFERENCES contest_rounds(round_id) ON DELETE CASCADE,
    entry_id                 BIGINT NOT NULL REFERENCES contest_entries(entry_id) ON DELETE CASCADE,
    current_version_no       INT NOT NULL DEFAULT 0,
    status                   submission_status_enum NOT NULL DEFAULT 'DRAFT',
    is_locked                BOOLEAN NOT NULL DEFAULT FALSE,
    submitted_at             TIMESTAMPTZ,
    created_by               BIGINT REFERENCES app_users(user_id) ON DELETE SET NULL,
    updated_by               BIGINT REFERENCES app_users(user_id) ON DELETE SET NULL,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (round_id, entry_id)
);

CREATE TABLE submission_versions (
    submission_version_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    submission_id            BIGINT NOT NULL REFERENCES submissions(submission_id) ON DELETE CASCADE,
    version_no               INT NOT NULL,
    title                    VARCHAR(255),
    description              TEXT,
    external_link            TEXT,
    text_answer              TEXT,
    checksum_value           VARCHAR(128),
    submitted_by             BIGINT REFERENCES app_users(user_id) ON DELETE SET NULL,
    submitted_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    note                     TEXT,
    UNIQUE (submission_id, version_no)
);

CREATE TABLE submission_files (
    submission_file_id       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    submission_version_id    BIGINT NOT NULL REFERENCES submission_versions(submission_version_id) ON DELETE CASCADE,
    file_name                VARCHAR(255) NOT NULL,
    file_url                 TEXT NOT NULL,
    mime_type                VARCHAR(100),
    file_size_bytes          BIGINT,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_submissions_updated_at
BEFORE UPDATE ON submissions
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- =========================================================
-- 8) RUBRIC / JUDGE ASSIGNMENT / SCORE / RESULT
-- =========================================================

CREATE TABLE round_score_criteria (
    criterion_id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    round_id                 BIGINT NOT NULL REFERENCES contest_rounds(round_id) ON DELETE CASCADE,
    criterion_name           VARCHAR(150) NOT NULL,
    description              TEXT,
    max_score                NUMERIC(8,2) NOT NULL CHECK (max_score >= 0),
    weight_percent           NUMERIC(5,2) CHECK (weight_percent >= 0 AND weight_percent <= 100),
    display_order            INT NOT NULL DEFAULT 1,
    UNIQUE (round_id, criterion_name),
    UNIQUE (round_id, display_order)
);

CREATE TABLE judge_assignments (
    assignment_id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    round_id                 BIGINT NOT NULL REFERENCES contest_rounds(round_id) ON DELETE CASCADE,
    entry_id                 BIGINT NOT NULL REFERENCES contest_entries(entry_id) ON DELETE CASCADE,
    submission_id            BIGINT REFERENCES submissions(submission_id) ON DELETE SET NULL,
    judge_id                 BIGINT NOT NULL REFERENCES judges(judge_id) ON DELETE CASCADE,
    assigned_by              BIGINT REFERENCES app_users(user_id) ON DELETE SET NULL,
    can_view_identity        BOOLEAN NOT NULL DEFAULT FALSE,
    assigned_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (round_id, entry_id, judge_id)
);

CREATE TABLE scores (
    score_id                 BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    assignment_id            BIGINT NOT NULL REFERENCES judge_assignments(assignment_id) ON DELETE CASCADE,
    criterion_id             BIGINT NOT NULL REFERENCES round_score_criteria(criterion_id) ON DELETE CASCADE,
    score_value              NUMERIC(8,2) NOT NULL CHECK (score_value >= 0),
    comment_text             TEXT,
    scored_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (assignment_id, criterion_id)
);

CREATE TABLE round_results (
    round_result_id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    round_id                 BIGINT NOT NULL REFERENCES contest_rounds(round_id) ON DELETE CASCADE,
    entry_id                 BIGINT NOT NULL REFERENCES contest_entries(entry_id) ON DELETE CASCADE,
    total_score              NUMERIC(10,2),
    average_score            NUMERIC(10,2),
    rank_no                  INT,
    is_passed                BOOLEAN,
    published_at             TIMESTAMPTZ,
    generated_by             BIGINT REFERENCES app_users(user_id) ON DELETE SET NULL,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (round_id, entry_id)
);

CREATE TABLE contest_results (
    contest_result_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    contest_id               BIGINT NOT NULL REFERENCES contests(contest_id) ON DELETE CASCADE,
    entry_id                 BIGINT NOT NULL REFERENCES contest_entries(entry_id) ON DELETE CASCADE,
    final_score              NUMERIC(10,2),
    rank_no                  INT,
    award_title              VARCHAR(255),
    -- NEW: trạng thái phê duyệt BCN_QD2 (denormalize cho query nhanh)
    bcn_approval_status      approval_status_enum NOT NULL DEFAULT 'PENDING',
    published_at             TIMESTAMPTZ,
    generated_by             BIGINT REFERENCES app_users(user_id) ON DELETE SET NULL,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (contest_id, entry_id)
);

CREATE TABLE result_appeals (
    appeal_id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    contest_id               BIGINT NOT NULL REFERENCES contests(contest_id) ON DELETE CASCADE,
    round_id                 BIGINT REFERENCES contest_rounds(round_id) ON DELETE SET NULL,
    entry_id                 BIGINT NOT NULL REFERENCES contest_entries(entry_id) ON DELETE CASCADE,
    submitted_by_student_id  BIGINT NOT NULL REFERENCES students(student_id) ON DELETE RESTRICT,
    title                    VARCHAR(255) NOT NULL,
    content_text             TEXT NOT NULL,
    status                   appeal_status_enum NOT NULL DEFAULT 'PENDING',
    response_text            TEXT,
    handled_by               BIGINT REFERENCES app_users(user_id) ON DELETE SET NULL,
    handled_at               TIMESTAMPTZ,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_result_appeals_updated_at
BEFORE UPDATE ON result_appeals
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- =========================================================
-- 9) CHECK-IN / QR
-- =========================================================

CREATE TABLE checkin_qr_tokens (
    qr_token_id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    session_id               BIGINT NOT NULL REFERENCES contest_sessions(session_id) ON DELETE CASCADE,
    token_value              VARCHAR(255) NOT NULL UNIQUE,
    expires_at               TIMESTAMPTZ NOT NULL,
    is_active                BOOLEAN NOT NULL DEFAULT TRUE,
    created_by               BIGINT REFERENCES app_users(user_id) ON DELETE SET NULL,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE checkins (
    checkin_id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    session_id               BIGINT NOT NULL REFERENCES contest_sessions(session_id) ON DELETE CASCADE,
    student_id               BIGINT NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    entry_id                 BIGINT REFERENCES contest_entries(entry_id) ON DELETE SET NULL,
    qr_token_id              BIGINT REFERENCES checkin_qr_tokens(qr_token_id) ON DELETE SET NULL,
    method                   checkin_method_enum NOT NULL,
    status                   checkin_status_enum NOT NULL DEFAULT 'SUCCESS',
    checked_in_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    device_info              VARCHAR(255),
    UNIQUE (session_id, student_id)
);

-- =========================================================
-- 10) NOTIFICATION / ARTICLE / QUESTION
-- =========================================================

CREATE TABLE notifications (
    notification_id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    scope                    notification_scope_enum NOT NULL,
    contest_id               BIGINT REFERENCES contests(contest_id) ON DELETE CASCADE,
    title                    VARCHAR(255) NOT NULL,
    message                  TEXT NOT NULL,
    is_global                BOOLEAN NOT NULL DEFAULT FALSE,
    created_by               BIGINT REFERENCES app_users(user_id) ON DELETE SET NULL,
    published_at             TIMESTAMPTZ,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE notification_recipients (
    notification_id          BIGINT NOT NULL REFERENCES notifications(notification_id) ON DELETE CASCADE,
    user_id                  BIGINT NOT NULL REFERENCES app_users(user_id) ON DELETE CASCADE,
    is_read                  BOOLEAN NOT NULL DEFAULT FALSE,
    read_at                  TIMESTAMPTZ,
    PRIMARY KEY (notification_id, user_id)
);

CREATE TABLE articles (
    article_id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    contest_id               BIGINT REFERENCES contests(contest_id) ON DELETE CASCADE,
    title                    VARCHAR(255) NOT NULL,
    summary                  TEXT,
    content_html             TEXT NOT NULL,
    is_public                BOOLEAN NOT NULL DEFAULT TRUE,
    created_by               BIGINT REFERENCES app_users(user_id) ON DELETE SET NULL,
    published_at             TIMESTAMPTZ,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE questions (
    question_id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    contest_id               BIGINT REFERENCES contests(contest_id) ON DELETE CASCADE,
    asked_by_student_id      BIGINT NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    title                    VARCHAR(255) NOT NULL,
    content_text             TEXT NOT NULL,
    status                   question_status_enum NOT NULL DEFAULT 'OPEN',
    is_public                BOOLEAN NOT NULL DEFAULT FALSE,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE question_answers (
    answer_id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    question_id              BIGINT NOT NULL REFERENCES questions(question_id) ON DELETE CASCADE,
    answered_by              BIGINT NOT NULL REFERENCES app_users(user_id) ON DELETE RESTRICT,
    content_text             TEXT NOT NULL,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_articles_updated_at
BEFORE UPDATE ON articles
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_questions_updated_at
BEFORE UPDATE ON questions
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- =========================================================
-- 11) WORKFLOW APPROVAL (BTC ↔ BCN, 2 cấp QĐ1 + QĐ2) -- NEW
-- =========================================================
-- Một cuộc thi có thể có nhiều record approval:
--   - 1 record cho CONTEST_PROPOSAL (BCN_QD1) — có thể lặp lại nếu BCN
--     yêu cầu chỉnh sửa nhiều lần (revision_round = 1, 2, 3...)
--   - 1 record cho CONTEST_RESULT (BCN_QD2) — sau khi BTC chốt kết quả
-- Bảng này là nguồn truth duy nhất cho lịch sử phê duyệt.
-- =========================================================

CREATE TABLE workflow_approvals (
    approval_id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    target_type              approval_target_enum NOT NULL,
    contest_id               BIGINT NOT NULL REFERENCES contests(contest_id) ON DELETE CASCADE,
    step                     approval_step_enum NOT NULL,
    status                   approval_status_enum NOT NULL DEFAULT 'PENDING',
    revision_round           INT NOT NULL DEFAULT 1,
    -- Người submit (BTC) và người duyệt (BCN)
    submitted_by             BIGINT NOT NULL REFERENCES app_users(user_id) ON DELETE RESTRICT,
    submitted_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    submission_note          TEXT,
    reviewed_by              BIGINT REFERENCES app_users(user_id) ON DELETE SET NULL,
    reviewed_at              TIMESTAMPTZ,
    bcn_comment              TEXT,
    -- Snapshot key fields tại thời điểm submit (audit/rollback nếu cần)
    snapshot_json            JSONB,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- target_type ↔ step phải khớp:
    CONSTRAINT chk_target_step_match CHECK (
        (target_type = 'CONTEST_PROPOSAL' AND step = 'BCN_QD1')
        OR (target_type = 'CONTEST_RESULT' AND step = 'BCN_QD2')
    ),
    -- Mỗi (contest, target, revision) chỉ có 1 record
    UNIQUE (contest_id, target_type, revision_round)
);

CREATE TRIGGER trg_workflow_approvals_updated_at
BEFORE UPDATE ON workflow_approvals
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- =========================================================
-- 12) AUDIT LOG
-- =========================================================

CREATE TABLE audit_logs (
    log_id                   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id                  BIGINT REFERENCES app_users(user_id) ON DELETE SET NULL,
    action_type              VARCHAR(100) NOT NULL,
    entity_name              VARCHAR(100) NOT NULL,
    entity_id                VARCHAR(100),
    ip_address               INET,
    details_json             JSONB,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =========================================================
-- 13) INDEXES
-- =========================================================

CREATE INDEX idx_user_roles_role_id
ON user_roles(role_id);

CREATE INDEX idx_app_users_email
ON app_users(email);

CREATE INDEX idx_majors_faculty
ON majors(faculty_id);

CREATE INDEX idx_academic_classes_major
ON academic_classes(major_id);

CREATE INDEX idx_student_directory_student_code
ON student_directory(student_code);

CREATE INDEX idx_student_directory_email
ON student_directory(ptit_email);

CREATE INDEX idx_student_directory_major
ON student_directory(major_id);

CREATE INDEX idx_students_user_id
ON students(user_id);

CREATE INDEX idx_organizers_faculty
ON organizers(faculty_id);

CREATE INDEX idx_dept_heads_faculty
ON department_heads(faculty_id);

CREATE INDEX idx_contests_status
ON contests(status);

CREATE INDEX idx_contests_host_faculty
ON contests(host_faculty_id);

CREATE INDEX idx_contests_proposed_by
ON contests(proposed_by);

CREATE INDEX idx_contests_reg_time
ON contests(registration_open_at, registration_close_at);

CREATE INDEX idx_contests_start_end
ON contests(start_at, end_at);

CREATE INDEX idx_contest_rounds_contest
ON contest_rounds(contest_id);

CREATE INDEX idx_contest_sessions_contest_round
ON contest_sessions(contest_id, round_id);

CREATE INDEX idx_teams_contest
ON teams(contest_id);

CREATE INDEX idx_contest_entries_contest_status
ON contest_entries(contest_id, registration_status, participant_status);

CREATE INDEX idx_session_entries_session
ON session_entries(session_id);

CREATE INDEX idx_session_entries_entry
ON session_entries(entry_id);

CREATE INDEX idx_submissions_round_entry
ON submissions(round_id, entry_id);

CREATE INDEX idx_submission_versions_submission
ON submission_versions(submission_id, version_no);

CREATE INDEX idx_submission_files_version
ON submission_files(submission_version_id);

CREATE INDEX idx_round_score_criteria_round
ON round_score_criteria(round_id);

CREATE INDEX idx_judge_assignments_judge
ON judge_assignments(judge_id);

CREATE INDEX idx_judge_assignments_round_entry
ON judge_assignments(round_id, entry_id);

CREATE INDEX idx_scores_assignment
ON scores(assignment_id);

CREATE INDEX idx_round_results_round
ON round_results(round_id);

CREATE INDEX idx_contest_results_contest
ON contest_results(contest_id);

CREATE INDEX idx_contest_results_bcn_status
ON contest_results(bcn_approval_status);

CREATE INDEX idx_checkins_session_student
ON checkins(session_id, student_id);

CREATE INDEX idx_notifications_scope_contest
ON notifications(scope, contest_id);

CREATE INDEX idx_notification_recipients_user
ON notification_recipients(user_id);

CREATE INDEX idx_questions_contest_status
ON questions(contest_id, status);

-- NEW indexes for workflow_approvals
CREATE INDEX idx_workflow_approvals_contest
ON workflow_approvals(contest_id);

CREATE INDEX idx_workflow_approvals_target_status
ON workflow_approvals(target_type, status);

CREATE INDEX idx_workflow_approvals_reviewed_by
ON workflow_approvals(reviewed_by);

CREATE INDEX idx_audit_logs_user_created
ON audit_logs(user_id, created_at);

CREATE INDEX idx_audit_logs_entity
ON audit_logs(entity_name, entity_id);

-- =========================================================
-- 14) OPTIONAL COMMENTS
-- =========================================================
COMMENT ON TABLE majors IS 'Ngành học (thuộc khoa)';
COMMENT ON TABLE department_heads IS 'Profile BCN khoa — gắn user_id với faculty_id, có flag primary_approver';
COMMENT ON TABLE contest_entries IS 'Đơn vị dự thi trung tâm: cá nhân hoặc đội';
COMMENT ON TABLE submissions IS 'Bài nộp của một đơn vị dự thi trong một vòng';
COMMENT ON TABLE submission_versions IS 'Lịch sử phiên bản bài nộp';
COMMENT ON TABLE round_score_criteria IS 'Rubric chấm điểm theo từng vòng';
COMMENT ON TABLE judge_assignments IS 'Phân công giám khảo chấm cho đơn vị dự thi';
COMMENT ON TABLE session_entries IS 'Gán đơn vị dự thi vào ca/phòng thi';
COMMENT ON TABLE workflow_approvals IS 'Phê duyệt 2 cấp BTC↔BCN: BCN_QD1 cho đề xuất cuộc thi, BCN_QD2 cho kết quả chung cuộc';
COMMENT ON COLUMN workflow_approvals.revision_round IS 'Lần submit thứ mấy (1, 2, 3...) — tăng mỗi khi BCN yêu cầu revision';
COMMENT ON COLUMN workflow_approvals.snapshot_json IS 'Snapshot key fields của contest tại thời điểm submit, dùng cho audit/rollback';
COMMENT ON COLUMN contests.proposed_by IS 'BTC (user_id) đề xuất cuộc thi — thường = created_by lúc submit lần đầu';
COMMENT ON COLUMN contests.host_faculty_id IS 'Khoa chủ trì — quyết định BCN nào duyệt (BCN_QD1, BCN_QD2)';
COMMENT ON COLUMN contest_results.bcn_approval_status IS 'Trạng thái phê duyệt BCN_QD2 (denormalize cho query nhanh, source of truth ở workflow_approvals)';
