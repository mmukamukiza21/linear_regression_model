
from pathlib import Path
import io

import joblib
import pandas as pd

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, ConfigDict, Field, StrictBool, StrictFloat, StrictInt, StrictStr
from sklearn.base import clone


# File locations
API_FOLDER = Path(__file__).resolve().parent
MODEL_PATH = API_FOLDER / "best_model.pkl"
TRAINING_DATA_PATH = API_FOLDER / "training_data.csv"

# Input features and target
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
    "Rolling30Days"
]

TARGET_COLUMN = "DailyRevenue"

# Load the saved machine learning pipeline
model = joblib.load(MODEL_PATH)

# Create the FastAPI application
app = FastAPI(
    title="Daily Retail Revenue Prediction API",
    description="API for predicting daily retail revenue using a Random Forest model.",
    version="1.0.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://localhost:8000",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:8000"
    ],
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type", "Authorization"],
    allow_credentials=True
)


# Define and validate prediction inputs
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


# Root endpoint
@app.get("/")
def home():
    return {
        "message": "Daily Retail Revenue Prediction API is running."
    }


# Prediction endpoint
@app.post("/predict")
def predict_revenue(data: PredictionInput):
    input_data = pd.DataFrame([data.model_dump()])

    prediction = model.predict(input_data)[0]

    return {
        "country": data.Country,
        "predicted_daily_revenue": round(float(prediction), 2),
        "currency": "GBP"
    }


# Retraining endpoint
@app.post("/retrain")
async def retrain_model(file: UploadFile = File(...)):
    global model

    # Check that the uploaded file is a CSV
    if not file.filename or not file.filename.lower().endswith(".csv"):
        raise HTTPException(
            status_code=400,
            detail="Please upload a CSV file."
        )

    # Check that the original training data exists
    if not TRAINING_DATA_PATH.exists():
        raise HTTPException(
            status_code=500,
            detail="Original training data file was not found."
        )

    try:
        # Read the uploaded CSV file
        contents = await file.read()

        if not contents:
            raise HTTPException(
                status_code=400,
                detail="The uploaded CSV file is empty."
            )

        new_data = pd.read_csv(io.BytesIO(contents))

        if new_data.empty:
            raise HTTPException(
                status_code=400,
                detail="The uploaded CSV contains no records."
            )

        # Check required columns
        required_columns = FEATURE_COLUMNS + [TARGET_COLUMN]
        missing_columns = [
            column for column in required_columns
            if column not in new_data.columns
        ]

        if missing_columns:
            raise HTTPException(
                status_code=400,
                detail=f"Missing columns: {missing_columns}"
            )

        # Keep only the required columns
        new_data = new_data[required_columns].copy()

        # Validate Country
        if new_data["Country"].isna().any():
            raise HTTPException(
                status_code=400,
                detail="Country cannot be empty."
            )

        new_data["Country"] = new_data["Country"].astype(str).str.strip()

        if (new_data["Country"] == "").any():
            raise HTTPException(
                status_code=400,
                detail="Country cannot be empty."
            )

        # Validate the weekend field
        weekend_values = {
            True: True,
            False: False,
            "True": True,
            "False": False,
            "true": True,
            "false": False,
            1: True,
            0: False
        }

        new_data["IsWeekend"] = new_data["IsWeekend"].map(weekend_values)

        if new_data["IsWeekend"].isna().any():
            raise HTTPException(
                status_code=400,
                detail="IsWeekend must contain True or False."
            )

        # Convert numeric columns
        numeric_columns = [
            "Year", "Month", "Day", "DayOfWeek",
            "Lag1Day", "Lag7Days", "Rolling7Days",
            "Rolling30Days", TARGET_COLUMN
        ]

        for column in numeric_columns:
            new_data[column] = pd.to_numeric(
                new_data[column], errors="coerce"
            )

        if new_data[numeric_columns].isna().any().any():
            raise HTTPException(
                status_code=400,
                detail="Numeric columns must contain valid numbers."
            )

        # Check integer fields
        integer_columns = ["Year", "Month", "Day", "DayOfWeek"]

        for column in integer_columns:
            if (new_data[column] % 1 != 0).any():
                raise HTTPException(
                    status_code=400,
                    detail=f"{column} must contain whole numbers."
                )

        # Validate realistic ranges
        if not new_data["Year"].between(2009, 2035).all():
            raise HTTPException(status_code=400, detail="Year must be between 2009 and 2035.")

        if not new_data["Month"].between(1, 12).all():
            raise HTTPException(status_code=400, detail="Month must be between 1 and 12.")

        if not new_data["Day"].between(1, 31).all():
            raise HTTPException(status_code=400, detail="Day must be between 1 and 31.")

        if not new_data["DayOfWeek"].between(0, 6).all():
            raise HTTPException(status_code=400, detail="DayOfWeek must be between 0 and 6.")

        non_negative_columns = [
            "Lag1Day", "Lag7Days", "Rolling7Days",
            "Rolling30Days", TARGET_COLUMN
        ]

        for column in non_negative_columns:
            if (new_data[column] < 0).any():
                raise HTTPException(
                    status_code=400,
                    detail=f"{column} cannot be negative."
                )

        # Check that calendar dates are valid
        dates = pd.to_datetime(
            new_data[["Year", "Month", "Day"]].rename(
                columns={"Year": "year", "Month": "month", "Day": "day"}
            ),
            errors="coerce"
        )

        if dates.isna().any():
            raise HTTPException(
                status_code=400,
                detail="The CSV contains invalid calendar dates."
            )

        # Load the original training data
        original_data = pd.read_csv(TRAINING_DATA_PATH)

        # Combine original and newly uploaded records
        combined_data = pd.concat(
            [original_data[required_columns], new_data],
            ignore_index=True
        )

        # Create an unfitted copy of the existing pipeline
        updated_model = clone(model)

        # Retrain the model using the combined dataset
        updated_model.fit(
            combined_data[FEATURE_COLUMNS],
            combined_data[TARGET_COLUMN]
        )

        # Save the updated model
        joblib.dump(updated_model, MODEL_PATH)

        # Replace the model used by the prediction endpoint
        model = updated_model

        return {
            "message": "Model retrained successfully.",
            "original_training_rows": len(original_data),
            "new_rows_added": len(new_data),
            "total_training_rows": len(combined_data)
        }

    except HTTPException:
        raise

    except Exception as error:
        raise HTTPException(
            status_code=400,
            detail=f"Could not retrain the model: {str(error)}"
        )
