from sqlalchemy import Column, String, Integer, Boolean, DateTime
from sqlalchemy.orm import declarative_base
import datetime

Base = declarative_base()

class LessonModel(Base):
    __tablename__ = "lessons"
    id = Column(String, primary_key=True, index=True)
    grade = Column(Integer, nullable=False)
    subject = Column(String, nullable=False)
    type = Column(String, nullable=False)
    hindiText = Column(String, nullable=False)
    santaliText = Column(String, nullable=True)
    phoneticGuide = Column(String, nullable=True)
    santaliAudioRef = Column(String, nullable=True)
    confidence = Column(String, nullable=True)
    outcomeIds = Column(String, nullable=True)

class VocabularyModel(Base):
    __tablename__ = "vocabulary"
    id = Column(String, primary_key=True, index=True)
    hindiWord = Column(String, nullable=False)
    santaliWord = Column(String, nullable=True)
    phoneticGuide = Column(String, nullable=True)
    category = Column(String, nullable=False)
    santaliAudioRef = Column(String, nullable=True)
    iconRef = Column(String, nullable=True)
    confidence = Column(String, nullable=True)

class CorrectionModel(Base):
    __tablename__ = "corrections"
    id = Column(String, primary_key=True, index=True)
    sourceText = Column(String, nullable=False)
    originalOutput = Column(String, nullable=False)
    correctedOutput = Column(String, nullable=False)
    correctorType = Column(String, nullable=False)
    receivedAt = Column(DateTime, default=datetime.datetime.utcnow)
