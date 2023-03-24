---
author: "Nicholas Lichtsinn"
date: "3/29/2022"
output: html_document
---

```{r}
#install.packages("ggplot2")
#install.packages("wordspace")
#install.packages("tidyverse")
#install.packages("dendextend")
#install.packages("randomcoloR")
#install.packages("rpart")
#install.packages("randomForest")
#install.packages("randomForestExplainer")
```

```{r}
library(cluster)
library(factoextra)
library(ggplot2)
library(wordspace)
library(tidyverse)
library(dendextend)
library(randomcoloR)
library(rpart)
library(rpart.plot)
library(randomForest)
library(randomForestExplainer)
```

```{r}
# reading in the dataset
papers <- read.csv("/Users/nickl/Documents/Syracuse/IST 707 - Data Analytics/fedPapers85.csv")
```

```{r}
# breakdown of auhorship
table(papers[,1])
```


```{r}
# build data frame for each author
papersHam <- papers[papers$author == "Hamilton",]
papersHM <- papers[papers$author == "HM",]
papersJay <- papers[papers$author == "Jay",]
papersMad <- papers[papers$author == "Madison",]
```

```{r}
# function to find the average tfidf of a word for a specific vector
createWordMean <- function(x) {
  y <- ncol(x)
  x <- colMeans(x[,3:y])
  newVec_1 <- c()
  for (i in 1:length(x)) {
    newVec_1[i] <- x[[i]]
  }
  print(newVec_1)
}
```

```{r}
# Running the function on each subsetted dataframe
ham_Vec <- createWordMean(papersHam)
HM_Vec <- createWordMean(papersHM)
Jay_Vec <- createWordMean(papersJay)
mad_Vec <- createWordMean(papersMad)
columns <- colnames(papersHam)

```

```{r}
# Putting the results into a dataframe
newFrame <- papersHam
newFrame <- data.frame(rbind(ham_Vec,HM_Vec,Jay_Vec,mad_Vec))

# naming the columns correctly
colnames(newFrame) <- columns[3:length(columns)]

# dataframe is average tfidf of a word for each author
newFrame[,1:3]
```

```{r}
# Calculating the top 40% of words used by each author
wordVariance <- sapply(newFrame, var)

# order and plotting results
ordered <- sort(wordVariance, decreasing = TRUE)
plot(ordered)

```

```{r}
# setting the top 40% of words
t40 <- data.frame(ordered[1:(length(ordered)*2/5)])

# number of words chosen
length(rownames(t40))

# words chosen
rownames(t40)

```

```{r}
#creating a dataFrame of only the top 40 words
smallFrame <- papers[,c("author", "filename",rownames(t40))]

# renaming rows with corresponding filename and saving as csv
rownames(smallFrame) <- smallFrame$filename
rownames(papers) <- papers$filename
write.csv(smallFrame,"/Users/nickl/Documents/Syracuse/IST 707 - Data Analytics/fedPapers_varianceframe.csv")
write.csv(papers,"/Users/nickl/Documents/Syracuse/IST 707 - Data Analytics/fedPapers_FullPapersframe.csv")

```

```{r}
# reloading the data for decision tree analysis with Jay and Hamilton&Madison papers removed as these are the two writers of interest
set.seed(1234)
treeData_small <- read.csv("/Users/nickl/Documents/Syracuse/IST 707 - Data Analytics/fedPapers_varianceframe.csv")
treeData_small <- treeData_small[,-1]

treeData_small <- subset(treeData_small, author != 'Jay')
treeData_small <- subset(treeData_small, author != 'HM')
treeData_small <- droplevels(treeData_small)
treeData_small <- treeData_small[,-2]
treeData_small <- treeData_small[,c(2:ncol(treeData_small),1)]

treeData_small_disputed <- treeData_small[1:11,]
treeData_small_full_noD <- treeData_small[-c(1:11),]

treeData_small_full_noD
```

```{r}
# indexing to get an even proportion of Hamilton and Madison papers in train and test sets
indexes <- sample(1:55, .65*length(1:55))
indexes <- c(indexes, sample(56:nrow(treeData_small_full_noD), .65*length(56:nrow(treeData_small_full_noD))))
```

```{r}
# creating fully unpruned decision tree model
tree_model1 <- rpart(author ~ . ,data = treeData_small_full_noD[indexes,]
                     , method = 'class'
                     , control = rpart.control(minbucket = 1, minsplit = 1, cp=-1)
                     , model = T
                     )
rsq.rpart(tree_model1)
```

```{r}
# plotting unpruned model
rpart.plot(tree_model1)

```

```{r}
preds1 <- predict(tree_model1, treeData_small_full_noD[-indexes,], type = 'class')
table(treeData_small_full_noD$author[-indexes],preds1)
```


```{r}
# pruning the tree
tree_model2 <- rpart(author ~ . , data = treeData_small_full_noD[indexes,], method = 'class', model = TRUE)
rsq.rpart(tree_model2)
```


```{r}
# plotting pruned model
rpart.plot(tree_model2)
```


```{r}
preds2 <- predict(tree_model2, treeData_small_full_noD[-indexes,], type = 'class')
table(treeData_small_full_noD$author[-indexes],preds2)
```


```{r}
# predicting the disputed articles
tree_model1 <- rpart(author ~ . , data = treeData_small_full_noD
                     , method = 'class'
                     , control = rpart.control(minbucket = 1, minsplit = 1, cp=-1)
                     , model = T
                     )

tree_model2 <- rpart(author ~ . , data = treeData_small_full_noD, method = 'class', model = TRUE)

# predicting the disputed articles with the unpruned model
predict(tree_model1, treeData_small_disputed, type = 'class')
# predicting the disputed articles with the pruned model
predict(tree_model2, treeData_small_disputed, type = 'class')
```

```{r}
# predicting the disputed articles with the pruned model
predict(tree_model2, treeData_small_disputed, type = 'class')
```


```{r}
preds2 <- predict(tree_model2, treeData_small_full_noD[-indexes,], type = 'class')
table(treeData_small_full_noD$author[-indexes],preds2)
```
