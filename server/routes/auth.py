
import uuid
import bcrypt
from fastapi import Depends, HTTPException, Header
from middleware.auth_middleware import auth_middleware
from models.user import User
from pydantic_schemas.user_create import UserCreate
from fastapi import APIRouter
from sqlalchemy.orm import Session
from database import get_db
from pydantic_schemas.user_login import UserLogin
from sqlalchemy.orm import joinedload
import jwt
from datetime import datetime, timedelta, timezone

router = APIRouter()

@router.post('/signup', status_code=201)
def signup_user(user: UserCreate, db: Session=Depends(get_db)):
    # check if the user already exists in db
    user_db = db.query(User).filter(User.email == user.email).first()
    
    if user_db:
        raise HTTPException(400, 'User with the same email already exists!') 
    
    hashed_pw = bcrypt.hashpw(user.password.encode(), bcrypt.gensalt())
    user_db = User(id=str(uuid.uuid4()), email = user.email, password = hashed_pw, name=user.name)
   
    # add the user to the db
    db.add(user_db)
    db.commit()
    db.refresh(user_db)

    return user_db

@router.post('/login')
def login_user(user: UserLogin, db: Session = Depends(get_db)):

    user_db = db.query(User).filter(User.email == user.email).first()
    if not user_db:
        raise HTTPException(400, 'User with this email does not exist!')
    
    is_match = bcrypt.checkpw(user.password.encode(), user_db.password)
    if not is_match:
        raise HTTPException(400, 'Incorrect password!')
    

    tiempo_expiracion = datetime.now(timezone.utc) + timedelta(seconds=120)
    
    payload = {
        'id': user_db.id,
        'exp': tiempo_expiracion  # El middleware buscará exactamente esta clave 'exp'
    }
    
    # 5. Firmas el token
    token = jwt.encode(payload, 'password_key', algorithm='HS256')
    
    # --- FIN DE LO NUEVO ---
    
    return {'token': token, 'user': user_db}

@router.get('/')
def current_user_data(db: Session = Depends(get_db), user_dict = Depends(auth_middleware)):
    user = db.query(User).filter(User.id == user_dict['uid']).options(
        joinedload(User.favorites)
    ).first()

    if not user:
        raise HTTPException(404, 'User not found!')
    
    return user