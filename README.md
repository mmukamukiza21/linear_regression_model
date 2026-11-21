# Daily Retail Revenue Predictor

A project that uses machine learning to use regression model to predict daily retail revenue, a FastAPI backend, and Flutter mobile application.

## 1. Project Overview

The Daily Retail Revenue Predictor is a machine learning system designed to forecast the daily retail revenue based on the historical retail data. This project consists of data analysis, development of the model, an API for making predictions and a mobile application for users.

## 2. Project Objectives

- Identify and create retail sales information.
Compare and train various regression models.
- Save trained machine learning model.
- Create a backend using FastAPI for making revenue predictions.
- Create a Flutter mobile application to communicate with API.
- Ensure users can feed in new data to retrain the model.

## 3. Machine Learning Models

The project investigates and contrasts four regression models namely:

- Linear Regression
- SGDRegressor
- Decision Tree Regressor
- Random Forest Regressor

Notebook includes data exploration, model training, model evaluation and visualizations.

## 4. Project Structure

```text
linear_regression_model/
│
├── README.md
├── .gitignore
│
└── summative/
    ├── API/
    │   ├── prediction.py
    │   ├── best_model.pkl
    │   ├── training_data.csv
    │   ├── new_retail_data.csv
    │   └── requirements.txt
    │
    ├── FlutterApp/
    │   ├── lib/
    │   │   └── main.dart
    │   ├── pubspec.yaml
    │   └── README.md
    │
    └── linear_regression/
        ├── multivariate.ipynb
        ├── inspect_data.py
        └── Untitled.ipynb
```

## 5. Technologies Used

- Python for data processing and machine learning.
- Pandas and NumPy for data manipulation.
- Scikit-learn regression models.
- Jupyter Notebook: Analysis and model training.
- Backend API written using fastapi.
- Flutter/Dart for mobile app.
- Using Git and GitHub for version control.

## 6. Running the Project

### A. Machine Learning Notebook

Open your PowerShell window and go to the project folder:

```powershell
cd C:\Users\HP\Documents\linear_regression_model\summative
```

Run the notebook:

```powershell
uv run jupyter notebook .\linear_regression\multivariate.ipynb
```

Open the notebook and execute all the cells for analysis, modelling training, evaluation and visualization.

### B. FastAPI Backend

Go to another PowerShell window and change into the API folder:

```powershell
cd C:\Users\HP\Documents\linear_regression_model\summative\API
```

Install the necessary packages:

```powershell
uv pip install -r requirements.txt
```

Start the API:

```powershell
uv run uvicorn prediction:app --reload --host 0.0.0.0
```

Open the API documentation in your browser:

http://127.0.0.1:8000/docs

### C. Flutter Mobile Application

Open another terminal and go to the Flutter application folder:

```powershell
cd C:\Users\HP\Documents\linear_regression_model\summative\FlutterApp
```

Install the flutter dependencies:

```powershell
flutter pub get
```

Run the application:

```powershell
flutter run
```

Make sure the FastAPI backend is running when testing predictions through the mobile application.

## 7. API Endpoints

The FastAPI backend provides the following endpoints:

| Method | Endpoint | Purpose |
|---|---|---|
GET | `/` | returns true if the API is running, otherwise returns false.
POST | `/predict` | Predicts the amount of revenue that will be generated in a day for a retail store. |
Retrain | `/retrain` | Retrains model on file-uploaded CSV file |

The interactive API documentation can be found at /docs.

## 8. Flutter Application

Flutter is an app that enables access to the prediction system via a mobile interface. The users input the necessary details and submit them to the FastAPI backend where they receive a forecasted daily revenue.

## 9. Testing

To ensure the project components were tested to ensure that:

The notebook is executed and shows analysis and model results.
Backend with FastAPI is successfully started.
- The API endpoints can be accessed through the documentation.
- Flutter application is installed on the emulator.
- Mobile app is able to talk to the backend to get predictions.

## 10. Conclusion

This project is an example of the application of machine learning for predicting the daily retail revenue. It integrates data-analysis, regression-models, API development, and mobile application development in a single system.

## Important Links

- **GitHub Repository:** https://github.com/mmukamukiza21/linear_regression_model
- **Project Demonstration Video:** https://youtu.be/lEKNBhD3IPY
- **API Documentation:** http://127.0.0.1:8000/docs
- **Dataset Source:** https://archive.ics.uci.edu/dataset/502/online+retail+ii
