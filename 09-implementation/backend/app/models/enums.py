"""Python enums map 1-1 với PostgreSQL ENUM types trong schema v03."""

from enum import Enum


class UserStatus(str, Enum):
    ACTIVE = "ACTIVE"
    LOCKED = "LOCKED"
    DELETED = "DELETED"


class RoleCode(str, Enum):
    ADMIN = "ADMIN"
    ORGANIZER = "ORGANIZER"
    JUDGE = "JUDGE"
    HOD = "HOD"
    STUDENT = "STUDENT"


class ContestStatus(str, Enum):
    DRAFT = "DRAFT"
    PROPOSED = "PROPOSED"
    REVISION_REQUESTED = "REVISION_REQUESTED"
    PUBLISHED = "PUBLISHED"
    REG_OPEN = "REG_OPEN"
    REG_CLOSED = "REG_CLOSED"
    ONGOING = "ONGOING"
    FINISHED = "FINISHED"
    CANCELLED = "CANCELLED"


class EntryType(str, Enum):
    INDIVIDUAL = "INDIVIDUAL"
    TEAM = "TEAM"


class RegistrationStatus(str, Enum):
    PENDING = "PENDING"
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"
    CANCELLED = "CANCELLED"


class ParticipantStatus(str, Enum):
    REGISTERED = "REGISTERED"
    CHECKED_IN = "CHECKED_IN"
    SUBMITTED = "SUBMITTED"
    ELIMINATED = "ELIMINATED"
    COMPLETED = "COMPLETED"


class DeliveryMode(str, Enum):
    ONLINE = "ONLINE"
    OFFLINE = "OFFLINE"
    HYBRID = "HYBRID"


class RoundType(str, Enum):
    QUALIFIER = "QUALIFIER"
    PRELIMINARY = "PRELIMINARY"
    SEMI_FINAL = "SEMI_FINAL"
    FINAL = "FINAL"
    OTHER = "OTHER"


class SessionType(str, Enum):
    ONLINE = "ONLINE"
    OFFLINE = "OFFLINE"


class SubmissionStatus(str, Enum):
    DRAFT = "DRAFT"
    SUBMITTED = "SUBMITTED"
    LOCKED = "LOCKED"
    LATE = "LATE"
    CANCELLED = "CANCELLED"


class CheckinMethod(str, Enum):
    QR = "QR"
    MANUAL = "MANUAL"
    ONLINE = "ONLINE"


class CheckinStatus(str, Enum):
    SUCCESS = "SUCCESS"
    FAILED = "FAILED"


class NotificationScope(str, Enum):
    SYSTEM = "SYSTEM"
    CONTEST = "CONTEST"


class QuestionStatus(str, Enum):
    OPEN = "OPEN"
    ANSWERED = "ANSWERED"
    CLOSED = "CLOSED"


class AppealStatus(str, Enum):
    PENDING = "PENDING"
    IN_REVIEW = "IN_REVIEW"
    ACCEPTED = "ACCEPTED"
    REJECTED = "REJECTED"
    CLOSED = "CLOSED"


class ApprovalTarget(str, Enum):
    CONTEST_PROPOSAL = "CONTEST_PROPOSAL"
    CONTEST_RESULT = "CONTEST_RESULT"


class ApprovalStep(str, Enum):
    BCN_QD1 = "BCN_QD1"
    BCN_QD2 = "BCN_QD2"


class ApprovalStatus(str, Enum):
    PENDING = "PENDING"
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"
    REVISION_REQUESTED = "REVISION_REQUESTED"


class ConfigValueType(str, Enum):
    INT = "INT"
    STRING = "STRING"
    BOOL = "BOOL"
    JSON = "JSON"
