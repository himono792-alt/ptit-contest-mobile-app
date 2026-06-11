"""SQLAlchemy 2.0 models cho schema `ptit_contest` v03.

Import tất cả model ở đây để Alembic autogenerate detect được.
"""
# ruff: noqa: F401, I001

from app.models.base import Base
from app.models.identity import Role, AppUser, UserRole
from app.models.master_data import (
    Faculty, Major, AcademicClass, StudentDirectory,
    Student, Organizer, Judge, DepartmentHead,
)
from app.models.contest import (
    Contest, ContestOrganizer, ContestRound, ContestSession, ContestJudge,
)
from app.models.entry import (
    Team, TeamMember, ContestEntry, EntryStatusLog, SessionEntry,
)
from app.models.submission import Submission, SubmissionVersion, SubmissionFile
from app.models.judging import (
    RoundScoreCriterion, JudgeAssignment, Score,
    RoundResult, ContestResult, ResultAppeal,
)
from app.models.certificate import CertificateTemplate, IssuedCertificate
from app.models.checkin import CheckinQrToken, Checkin
from app.models.notification import (
    Notification, NotificationRecipient, Article, Question, QuestionAnswer,
)
from app.models.review import ContestReview
from app.models.workflow import WorkflowApproval
from app.models.system import SystemConfig, AuditLog
