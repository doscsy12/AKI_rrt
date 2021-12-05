# Datathon team : Prediction of patients requiring early/delayed dialysis treatment

# Problem Statement
Which are the features that will lead to AKI patients in ICU to receive delayed dialysis (>8h)?

## Background
In life-threatening cases, early dialysis can be life-saving. However, some patients can regain kidney function without dialysis, in the absence of life-threatening complications. The questions of when to start dialysis, and in which patients, are the subject of intense debate. The ELAIN trial found that early dialysis reduced mortality at 90 days, while the STARRT-AKI trial found that early dialysis was not associated with a lower risk of death. These high-profile randomised controlled trials only lead to more confusion in the field.

## Data and Model
Adult patients with AKI who were in ICU for the first time were extracted from MIMIC-IV database.

The metric of interest is the roc_auc score. This provides us a measure of how the model can distinguish between patients receiving early or delayed dialysis.

Logistic regression model was built to classify patients receiving renal replacement therapy. SMOTE was used to address the class imbalance within the dataset. And ridge regularisation was added to reduce the likelihood of overfitting. Accuracy was 0.73.

## Primary findings
| Feature                    | Coefficients |
|----------------------------|--------------|
| Min blood urea nitrogen    | 1.74         |
| Max white blood cell count | 1.07         |
| Min bicarbonate            | 0.62         |
| Mean temperature           | 0.56         |
| Min hematocrit             | 0.55         |

The above table shows minimum blood urea nitrogen is 3x more likely to predict delayed dialysis than minimum hematocrit. These features are clinically relevant. Patients with higher white blood cell counts and higher mean temperature may be septic, and may be better treated with antibiotics first. Dialysis may only be started after 8 hours, if their condition fails to improve.

## Conclusion and recommendation
We successfully explored a logistic regression model to classify AKI patients, who received delay renal therapy.

It would be interesting to compare the outcomes of patients who underwent early and delayed dialysis. We could also include polynomial features since a preliminary analysis showed that an interaction of variables such as maximum anion gap and mean blood pressure may have a higher predictive model during classification. Lastly, we want to explore boosting models as they may provide better accuracy. 
