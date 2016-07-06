##### Chapter 4: Classification using Naive Bayes --------------------

## Example: Filtering spam SMS messages ----
## Step 2: Exploring and preparing the data ---- 

# read the sms data into the sms data frame
sms_raw <- read.csv("sms_spam.csv", stringsAsFactors = FALSE)

# examine the structure of the sms data
str(sms_raw)

# convert spam/ham to factor.
sms_raw$type <- factor(sms_raw$type)

# examine the type variable more carefully
str(sms_raw$type)
table(sms_raw$type)

# build a corpus using the text mining (tm) package
library(tm)
sms_corpus <- Corpus(VectorSource(sms_raw$text))


# examine the sms corpus
print(sms_corpus)
inspect(sms_corpus[1:3])

# clean up the corpus using tm_map()
corpus_clean <- tm_map(sms_corpus, tolower)
corpus_clean <- tm_map(corpus_clean, removeNumbers)
corpus_clean <- tm_map(corpus_clean, removeWords, stopwords())
corpus_clean <- tm_map(corpus_clean, removePunctuation)
corpus_clean <- tm_map(corpus_clean, stripWhitespace)

# examine the clean corpus
inspect(sms_corpus[1:3])
inspect(corpus_clean[1:3])

# The fix.  There is an issue with tolower.
# https://www.safaribooksonline.com/a/machine-learning-with/65757/

corpus_clean <- tm_map(corpus_clean, PlainTextDocument)

# create a document-term sparse matrix
sms_dtm <- DocumentTermMatrix(corpus_clean)
print(sms_dtm)
dim(sms_dtm)

# creating training and test datasets
sms_raw_train <- sms_raw[1:4169, ]
str(sms_raw_train)
dim(sms_raw_train)
sms_raw_test  <- sms_raw[4170:5559, ]
str(sms_raw_test)
dim(sms_raw_test)

sms_dtm_train <- sms_dtm[1:4169,]
str(sms_dtm_train)
dim(sms_dtm_train)
sms_dtm_test  <- sms_dtm[4170:5559,]
str(sms_dtm_test)
dim(sms_dtm_test)

sms_corpus_train <- corpus_clean[1:4169]
length(sms_corpus_train)
sms_corpus_test  <- corpus_clean[4170:5559]
length(sms_corpus_test)

# check that the proportion of spam is similar
prop.table(table(sms_raw_train$type))
prop.table(table(sms_raw_test$type))

# word cloud visualization
library(wordcloud)

wordcloud(sms_corpus_train, min.freq = 30, random.order = FALSE)

# subset the training data into spam and ham groups
spam <- subset(sms_raw_train, type == "spam")
ham  <- subset(sms_raw_train, type == "ham")

wordcloud(spam$text, max.words = 40, scale = c(3, 0.5))
wordcloud(ham$text, max.words = 40, scale = c(3, 0.5))

# indicator features for frequent words
x <- findFreqTerms(sms_dtm_train, 5)
x
str(x)

# The fix.
# sms_dict <- Dictionary(findFreqTerms(sms_dtm_train, 5))
# http://rstudio-pubs-static.s3.amazonaws.com/17045_484d656f802c44eb82b8bad892e96faa.html

sms_dict <- c(findFreqTerms(sms_dtm_train, 5))
length(sms_dict)
sms_train <- DocumentTermMatrix(sms_corpus_train, list(dictionary = sms_dict))
dim(sms_train)
sms_test  <- DocumentTermMatrix(sms_corpus_test, list(dictionary = sms_dict))
dim(sms_test)

# convert counts to a factor
convert_counts <- function(x) {
  x <- ifelse(x > 0, 1, 0)
  x <- factor(x, levels = c(0, 1), labels = c("No", "Yes"))
}

# apply() convert_counts() to columns of train/test data
sms_train <- apply(sms_train, MARGIN = 2, convert_counts)
dim(sms_train)
sms_test  <- apply(sms_test, MARGIN = 2, convert_counts)
dim(sms_test)

summary(sms_train[, 1:5])

## Step 3: Training a model on the data ----
library(e1071)
sms_classifier <- naiveBayes(sms_train, sms_raw_train$type)

names(sms_classifier)
sms_classifier$tables[1:2]

sms_classifier

## Step 4: Evaluating model performance ----
sms_test_pred <- predict(sms_classifier, sms_test)

library(gmodels)
CrossTable(sms_test_pred, sms_raw_test$type,
           prop.chisq = FALSE, prop.t = FALSE, prop.r = FALSE,
           dnn = c('predicted', 'actual'))

## Step 5: Improving model performance ----
sms_classifier2 <- naiveBayes(sms_train, sms_raw_train$type, laplace = 1)
sms_test_pred2 <- predict(sms_classifier2, sms_test)
CrossTable(sms_test_pred2, sms_raw_test$type,
           prop.chisq = FALSE, prop.t = FALSE, prop.r = FALSE,
           dnn = c('predicted', 'actual'))

sms_classifier3 <- naiveBayes(sms_train, sms_raw_train$type, laplace = 2)
sms_test_pred3 <- predict(sms_classifier3, sms_test)
CrossTable(sms_test_pred3, sms_raw_test$type,
           prop.chisq = FALSE, prop.t = FALSE, prop.r = FALSE,
           dnn = c('predicted', 'actual'))