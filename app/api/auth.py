from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status, Response, Request
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.db.database import get_db
from app.db.models import Admin
from app.core.security import verify_password, create_access_token, decode_access_token, get_password_hash

router = APIRouter(prefix="/api/auth", tags=["Authentication"])

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/token", auto_error=False)

class LoginRequest(BaseModel):
    username: str
    password: str

class PasswordChangeRequest(BaseModel):
    old_password: str
    new_password: str

async def get_current_admin(
    request: Request,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
) -> Admin:
    # Check Bearer Header or HTTP-Only Cookie
    jwt_token = token or request.cookies.get("access_token")
    if not jwt_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication token missing",
            headers={"WWW-Authenticate": "Bearer"},
        )

    payload = decode_access_token(jwt_token)
    if not payload or "sub" not in payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    username = payload["sub"]
    result = await db.execute(select(Admin).filter_by(username=username, is_active=True))
    admin = result.scalar_one_or_none()
    if not admin:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found or disabled")

    return admin

@router.post("/token")
async def login_for_access_token(
    response: Response,
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_db)
):
    """Standard OAuth2 form login for Swagger docs and API clients."""
    result = await db.execute(select(Admin).filter_by(username=form_data.username))
    admin = result.scalar_one_or_none()

    if not admin or not verify_password(form_data.password, admin.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    admin.last_login = datetime.now(timezone.utc)
    await db.commit()

    token = create_access_token(data={"sub": admin.username})
    response.set_cookie(
        key="access_token",
        value=token,
        httponly=True,
        max_age=60 * 60 * 24 * 7,
        samesite="lax",
        secure=False
    )
    return {"access_token": token, "token_type": "bearer"}

@router.post("/login")
async def login_json(
    response: Response,
    credentials: LoginRequest,
    db: AsyncSession = Depends(get_db)
):
    """JSON-based login endpoint for Web Frontend."""
    result = await db.execute(select(Admin).filter_by(username=credentials.username))
    admin = result.scalar_one_or_none()

    if not admin or not verify_password(credentials.password, admin.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password"
        )

    admin.last_login = datetime.now(timezone.utc)
    await db.commit()

    token = create_access_token(data={"sub": admin.username})
    response.set_cookie(
        key="access_token",
        value=token,
        httponly=True,
        max_age=60 * 60 * 24 * 7,
        samesite="lax",
        secure=False
    )
    return {"success": True, "access_token": token, "token_type": "bearer"}

@router.post("/logout")
async def logout(response: Response):
    """Clears authentication cookies."""
    response.delete_cookie(key="access_token")
    return {"success": True, "message": "Logged out successfully"}

@router.get("/me")
async def get_me(current_admin: Admin = Depends(get_current_admin)):
    """Returns profile information for the authenticated admin."""
    return {
        "id": current_admin.id,
        "username": current_admin.username,
        "is_active": current_admin.is_active,
        "created_at": current_admin.created_at,
        "last_login": current_admin.last_login
    }

@router.post("/change-password")
async def change_password(
    data: PasswordChangeRequest,
    current_admin: Admin = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Allows authenticated admin to change their password."""
    if not verify_password(data.old_password, current_admin.password_hash):
        raise HTTPException(status_code=400, detail="Current password incorrect")

    current_admin.password_hash = get_password_hash(data.new_password)
    await db.commit()
    return {"success": True, "message": "Password changed successfully"}
