# Retail Revenue Predictor

## Project Description

Retail Revenue Predictor is a tool for determining the expected daily revenue based on the historical patterns of revenue.  
It utilizes Online Retail II data that has been cleaned, as well as features based on time and a trained Random Forest regression model.  
A FastAPI backend is implemented to enable the model to be retrained with new CSV data and provide predictions.  
A Flutter mobile application offers a straightforward interface for predicting the revenues.

## Dataset

The data for the project comes from the UCI Machine Learning Repository dataset called Online Retail II.

Dataset source: https://archive.ics.uci.edu/dataset/502/online+retail+ii

## Technologies Used

- Python
- Pandas and NumPy
- Scikit-learn
- Matplotlib and Seaborn
- FastAPI
- Flutter and Dart
- Git and GitHub
- Render

## Machine Learning Models

To train and evaluate four regression models:

1. Linear Regression
2. SGDRegressor
3. Decision Tree Regressor
4. Random Forest Regressor

The RFR had the highest test accuracy.

Name of Evaluation Metric | Random Forest |
|---|---:|
| Test MSE | 11,719,939.09 |
| Test RMSE | 3,423.44 |

Hyperparameter tuning was used to improve the SGDRegressor.

## API Deployment

The FastAPI backend is deployed on Render.

- **Live API Testing (Postman):** https://linear-regression-model-smp6.onrender.com/live-testing
The prediction endpoint is the POST /predict.The POST /predict is the endpoint for predictions.
This endpoint is used to retrain the model.Retraining endpoint: POST /retrain

The `/predict` endpoint takes in the features and returns a prediction of the revenue per day.

The `/retrain` endpoint takes a CSV file of new training data and retrains the model.

## Flutter Mobile Application

With the Flutter application, users can:

- Select a country.
- Choose a date to predict.
- Enter the 30 days of revenue that have already occurred.
- Determine the historical features needed.
- Send the information to the deployed API.
- See the forecasted daily revenue (GBP).

To run the Flutter Application, click the button.Click the button to run the Flutter Application!

Ensure that Flutter has been installed and an Android emulator setup or physical Android device connected.

Open the PowerShell window to the project folder and execute:

```powershell
cd summative\FlutterApp
flutter pub get
flutter run
```

The application is linked to the deployed Render API.

## Running the FastAPI Backend Locally

From the main project folder, run:

```powershell
uv sync --project .\summative
uv run --project .\summative uvicorn prediction:app --app-dir .\summative\API --reload
```

Open up the local Swagger file:

http://127.0.0.1:8000/docs

## Project Structure

```text
linear_regression_model/
│
├── summative/
│   ├── API/
│   │   ├── prediction.py
│   │   ├── best_model.pkl
│   │   ├── training_data.csv
│   │   └── requirements.txt
│   │
│   ├── FlutterApp/
│   │   └── lib/
│   │       └── main.dart
│   │
│   └── linear_regression/
│       └── model_training.ipynb
│
└── README.md
```

## Demonstration Video

This will require some time to get right.This will take some time to get right.

This demonstration will include the Flutter Application, API testing, evaluation of the machine learning model, and retraining the model.