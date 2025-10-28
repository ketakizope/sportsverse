"""
Facial Recognition utilities for SportsVerse attendance system.
Based on the reference implementation from Digital-Facial-Recognisation-Attendance-System.
"""

import os
import cv2
import numpy as np
import json
import pickle
from sklearn.ensemble import RandomForestClassifier
from django.conf import settings
import logging

logger = logging.getLogger(__name__)

# Model path for storing the trained classifier
MODEL_PATH = os.path.join(settings.BASE_DIR, 'face_recognition_model.pkl')

def crop_face_and_embed(bgr_image, detection):
    """
    Crop face from image and convert to embedding vector.
    Based on the reference implementation.
    """
    try:
        h, w = bgr_image.shape[:2]
        bbox = detection.location_data.relative_bounding_box
        x1 = int(max(0, bbox.xmin * w))
        y1 = int(max(0, bbox.ymin * h))
        x2 = int(min(w, (bbox.xmin + bbox.width) * w))
        y2 = int(min(h, (bbox.ymin + bbox.height) * h))
        
        if x2 <= x1 or y2 <= y1:
            return None
            
        face = bgr_image[y1:y2, x1:x2]
        face = cv2.cvtColor(face, cv2.COLOR_BGR2GRAY)
        face = cv2.resize(face, (32, 32), interpolation=cv2.INTER_AREA)
        emb = face.flatten().astype(np.float32) / 255.0
        return emb
    except Exception as e:
        logger.error(f"Error cropping face: {str(e)}")
        return None

def extract_embedding_for_image(image_path):
    """
    Extract face embedding from image file.
    """
    try:
        import mediapipe as mp
        
        mp_face = mp.solutions.face_detection.FaceDetection(
            model_selection=1, 
            min_detection_confidence=0.5
        )
        
        # Read image
        img = cv2.imread(image_path)
        if img is None:
            logger.error(f"Could not read image: {image_path}")
            return None
            
        # Process with MediaPipe
        results = mp_face.process(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
        
        if not results.detections:
            logger.warning("No face detected in image")
            return None
            
        emb = crop_face_and_embed(img, results.detections[0])
        return emb
        
    except ImportError:
        logger.error("MediaPipe not installed. Please install: pip install mediapipe")
        return None
    except Exception as e:
        logger.error(f"Error extracting embedding: {str(e)}")
        return None

def extract_embedding_from_bytes(image_bytes):
    """
    Extract face embedding from image bytes (for uploaded images).
    """
    try:
        import mediapipe as mp
        
        mp_face = mp.solutions.face_detection.FaceDetection(
            model_selection=1, 
            min_detection_confidence=0.5
        )
        
        # Convert bytes to numpy array
        arr = np.frombuffer(image_bytes, np.uint8)
        img = cv2.imdecode(arr, cv2.IMREAD_COLOR)
        
        if img is None:
            logger.error("Could not decode image from bytes")
            return None
            
        # Process with MediaPipe
        results = mp_face.process(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
        
        if not results.detections:
            logger.warning("No face detected in image")
            return None
            
        emb = crop_face_and_embed(img, results.detections[0])
        return emb
        
    except ImportError:
        logger.error("MediaPipe not installed. Please install: pip install mediapipe")
        return None
    except Exception as e:
        logger.error(f"Error extracting embedding from bytes: {str(e)}")
        return None

def load_model_if_exists():
    """
    Load the trained face recognition model if it exists.
    """
    if not os.path.exists(MODEL_PATH):
        logger.warning("Face recognition model not found")
        return None
        
    try:
        with open(MODEL_PATH, "rb") as f:
            return pickle.load(f)
    except Exception as e:
        logger.error(f"Error loading model: {str(e)}")
        return None

def predict_with_model(clf, emb):
    """
    Predict student ID using the trained model.
    Returns (student_id, confidence)
    """
    try:
        proba = clf.predict_proba([emb])[0]
        idx = np.argmax(proba)
        student_id = clf.classes_[idx]
        confidence = float(proba[idx])
        return student_id, confidence
    except Exception as e:
        logger.error(f"Error predicting with model: {str(e)}")
        return None, 0.0

def train_model_for_organization(organization):
    """
    Train face recognition model for a specific organization.
    """
    try:
        from .models import StudentProfile
        
        # Get all students with face encodings in this organization
        students = StudentProfile.objects.filter(
            organization=organization,
            face_encoding__isnull=False
        ).exclude(face_encoding='')
        
        if not students.exists():
            logger.warning(f"No students with face encodings found for organization {organization.id}")
            return False
            
        X = []
        y = []
        
        for student in students:
            try:
                # Parse face encoding from JSON
                face_encoding = json.loads(student.face_encoding)
                X.append(face_encoding)
                y.append(student.id)
            except (json.JSONDecodeError, TypeError) as e:
                logger.error(f"Error parsing face encoding for student {student.id}: {str(e)}")
                continue
                
        if len(X) == 0:
            logger.warning("No valid face encodings found for training")
            return False
            
        # Convert to numpy arrays
        X = np.array(X)
        y = np.array(y)
        
        # Train RandomForest classifier
        clf = RandomForestClassifier(
            n_estimators=150, 
            n_jobs=-1, 
            random_state=42
        )
        clf.fit(X, y)
        
        # Save model
        with open(MODEL_PATH, "wb") as f:
            pickle.dump(clf, f)
            
        logger.info(f"Face recognition model trained successfully for organization {organization.id}")
        return True
        
    except Exception as e:
        logger.error(f"Error training model: {str(e)}")
        return False

def recognize_student_from_image(image_bytes, organization):
    """
    Recognize student from image bytes.
    Returns (student, confidence) or (None, 0.0)
    """
    try:
        from .models import StudentProfile
        
        # Extract face embedding
        emb = extract_embedding_from_bytes(image_bytes)
        if emb is None:
            return None, 0.0
            
        # Load trained model
        clf = load_model_if_exists()
        if clf is None:
            logger.warning("No trained model available")
            return None, 0.0
            
        # Predict student ID
        student_id, confidence = predict_with_model(clf, emb)
        
        if confidence < 0.5:  # Threshold for recognition
            logger.info(f"Low confidence recognition: {confidence}")
            return None, confidence
            
        # Get student from database
        try:
            student = StudentProfile.objects.get(
                id=student_id,
                organization=organization
            )
            return student, confidence
        except StudentProfile.DoesNotExist:
            logger.warning(f"Student {student_id} not found in organization {organization.id}")
            return None, confidence
            
    except Exception as e:
        logger.error(f"Error recognizing student: {str(e)}")
        return None, 0.0
