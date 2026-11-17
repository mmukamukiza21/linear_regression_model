
from pathlib import Path
import io

import joblib
import numpy as np
import pandas as pd

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import (
    BaseModel,
    ConfigDict,
    Field,
    StrictBool,
    StrictFloat,
    StrictInt,
    StrictStr,
)
from sklearn.base import clone


# File locations
API_FOLDER = Path(__file__).resolve().parent
MODEL_PATH = API_FOLDER / "best_model.pkl"
TRAINING_DATA_PATH = API_FOLDER / "training_data.csv"

# Model input columns
FEATURE_COLUMNS = [
    "Country",
    "Year",
    "Month",
    "Day",
    "DayOfWeek",
    "IsWeekend",
    "Lag1Day",
    "Lag7Days",
    "Rolling7Days",
    "Rolling30Days",
]

TARGET_COLUMN = "DailyRevenue"
REQUIRED_COLUMNS = FEATURE_COLUMNS + [TARGET_COLUMN]

NUMERIC_COLUMNS = [
    "Year",
    "Month",
    "Day",
    "DayOfWeek",
    "IsWeekend",
    "Lag1Day",
    "Lag7Days",
    "Rolling7Days",
    "Rolling30Days",
    "DailyRevenue",
]

# Load the saved model
model = joblib.load(MODEL_PATH)


app = FastAPI(
    title="Daily Retail Revenue Prediction API",
    description="API for predicting daily retail revenue using a Random Forest model.",
    version="1.0.0",
)


# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://localhost:8000",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:8000",
    ],
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type", "Authorization"],
    allow_credentials=True,
)


# Prediction input validation
class PredictionInput(BaseModel):
    model_config = ConfigDict(extra="forbid")

    Country: StrictStr = Field(min_length=1, max_length=100)
    Year: StrictInt = Field(ge=2009, le=2035)
    Month: StrictInt = Field(ge=1, le=12)
    Day: StrictInt = Field(ge=1, le=31)
    DayOfWeek: StrictInt = Field(ge=0, le=6)
    IsWeekend: StrictBool
    Lag1Day: StrictFloat = Field(ge=0)
    Lag7Days: StrictFloat = Field(ge=0)
    Rolling7Days: StrictFloat = Field(ge=0)
    Rolling30Days: StrictFloat = Field(ge=0)


@app.get("/")
def home():
    return {
        "message": "Daily Retail Revenue Prediction API is running."
    }


# Predict daily revenue
@app.post("/predict")
def predict_revenue(data: PredictionInput):
    input_data = pd.DataFrame([data.model_dump()])
    prediction = model.predict(input_data)[0]

    return {
        "country": data.Country,
        "predicted_daily_revenue": round(float(prediction), 2),
        "currency": "GBP",
    }


# Validate the uploaded CSV file
def validate_training_data(data: pd.DataFrame):
    missing_columns = [
        column for column in REQUIRED_COLUMNS
        if column not in data.columns
    ]

    extra_columns = [
        column for column in data.columns
        if column not in REQUIRED_COLUMNS
    ]

    if missing_columns:
        raise HTTPException(
            status_code=400,
            detail=f"Missing columns: {missing_columns}",
        )

    if extra_columns:
        raise HTTPException(
            status_code=400,
            detail=f"Unexpected columns: {extra_columns}",
        )

    if data.empty:
        raise HTTPException(
            status_code=400,
            detail="The uploaded CSV file has no data rows.",
        )

    if data[REQUIRED_COLUMNS].isnull().any().any():
        raise HTTPException(
            status_code=400,
            detail="The CSV file contains missing values.",
        )

    data = data[REQUIRED_COLUMNS].copy()

    data["Country"] = data["Country"].astype(str).str.strip()

    if (data["Country"] == "").any():
        raise HTTPException(
            status_code=400,
            detail="Country values cannot be empty.",
        )

    for column in NUMERIC_COLUMNS:
        data[column] = pd.to_numeric(
            data[column],
            errors="coerce",
        )

    if data[NUMERIC_COLUMNS].isnull().any().any():
        raise HTTPException(
            status_code=400,
            detail="Some numerical columns contain invalid values.",
        )

    if not np.isfinite(data[NUMERIC_COLUMNS].to_numpy()).all():
        raise HTTPException(
            status_code=400,
            detail="Numerical values must be finite.",
        )

    integer_columns = [
        "Year",
        "Month",
        "Day",
        "DayOfWeek",
        "IsWeekend",
    ]

    for column in integer_columns:
        values = data[column].to_numpy()

        if not np.equal(values, np.floor(values)).all():
            raise HTTPException(
                status_code=400,
                detail=f"{column} must contain whole numbers.",
            )

    if not data["Year"].between(2009, 2035).all():
        raise HTTPException(status_code=400, detail="Year must be between 2009 and 2035.")

    if not data["Month"].between(1, 12).all():
        raise HTTPException(status_code=400, detail="Month must be between 1 and 12.")

    if not data["Day"].between(1, 31).all():
        raise HTTPException(status_code=400, detail="Day must be between 1 and 31.")

    if not data["DayOfWeek"].between(0, 6).all():
        raise HTTPException(status_code=400, detail="DayOfWeek must be between 0 and 6.")

    if not data["IsWeekend"].isin([0, 1]).all():
        raise HTTPException(status_code=400, detail="IsWeekend must be 0 or 1.")

    nonnegative_columns = [
        "Lag1Day",
        "Lag7Days",
        "Rolling7Days",
        "Rolling30Days",
        "DailyRevenue",
    ]

    for column in nonnegative_columns:
        if (data[column] < 0).any():
            raise HTTPException(
                status_code=400,
                detail=f"{column} cannot contain negative values.",
            )

    return data


# Retrain the model using an uploaded CSV file
@app.post("/retrain")
async def retrain_model(file: UploadFile = File(...)):
    global model

    if not file.filename or not file.filename.lower().endswith(".csv"):
        raise HTTPException(
            status_code=400,
            detail="Please upload a CSV file.",
        )

    contents = await file.read()

    if not contents:
        raise HTTPException(
            status_code=400,
            detail="The uploaded file is empty.",
        )

    if len(contents) > 20 * 1024 * 1024:
        raise HTTPException(
            status_code=413,
            detail="The uploaded file is too large. Maximum size is 20 MB.",
        )

    try:
        uploaded_data = pd.read_csv(io.BytesIO(contents))
    except Exception:
        raise HTTPException(
            status_code=400,
            detail="Could not read the uploaded CSV file.",
        )

    uploaded_data = validate_training_data(uploaded_data)

    if not TRAINING_DATA_PATH.exists():
        raise HTTPException(
            status_code=500,
            detail="Original training data file was not found.",
        )

    try:
        original_data = pd.read_csv(TRAINING_DATA_PATH)
        original_data = validate_training_data(original_data)

        combined_data = pd.concat(
            [original_data, uploaded_data],
            ignore_index=True,
        )

        X = combined_data[FEATURE_COLUMNS]
        y = combined_data[TARGET_COLUMN]

        # Create a fresh copy of the existing model pipeline
        retrained_model = clone(model)

        # Train using the original and newly uploaded data
        retrained_model.fit(X, y)

        # Save the updated model and combined training data
        joblib.dump(retrained_model, MODEL_PATH)
        combined_data.to_csv(TRAINING_DATA_PATH, index=False)

        # Use the newly trained model for future predictions
        model = retrained_model

        return {
            "message": "Model retrained successfully.",
            "uploaded_rows": len(uploaded_data),
            "total_training_rows": len(combined_data),
            "model_file": "best_model.pkl",
        }

    except HTTPException:
        raise
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=f"Model retraining failed: {str(error)}",
        )
