- correlation and regression: how variables relate, controlling for the others

confusion matrix (classifiers, diagnostic tests):

|                        | Actually positive   | Actually negative   |
|------------------------|---------------------|---------------------|
| **Predicted positive** | True positive (TP)  | False positive (FP) |
| **Predicted negative** | False negative (FN) | True negative (TN)  |

- Accuracy\
  How often was the prediction correct overall?\
  `(TP + TN) / all cases`

- Precision\
  Of the positive predictions, how many were right?\
  `TP / (TP + FP)`

- Recall / sensitivity / true-positive rate\
  Of the actual positives, how many did we find?\
  `TP / (TP + FN)`

- Specificity\
  Of the actual negatives, how many did we reject correctly?\
  `TN / (TN + FP)`

- False-positive rate\
  `FP / (FP + TN)`

- False-negative rate\
  `FN / (FN + TP)`
