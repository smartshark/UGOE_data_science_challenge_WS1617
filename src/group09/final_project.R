
########################
# Requirements
########################

# use mongolite
# Debian: libssl-dev, libsasl2-dev
if(!require(mongolite)) install.packages("mongolite")
library(mongolite)
# library(stringr)

# other library
library(e1071)
library(party)
if(!require(caret)) install.packages("caret")
library(caret)
if(!require(partykit)) install.packages("partykit")
library(partykit)

########################
# Data Preparation
########################

# Connection configuration
MONGO_URL = "mongodb://group9:HAFYergq@141.5.113.177:27017/smartshark_test"
# MONGOURL = "mongodb://group9:HAFYergq@141.5.113.177:27017/smartshark_test"
# MONGO_URL = "mongodb://localhost:27017/smartshark_test"

# Load data of the activities related to people
issue=mongo(collection="issue",url=MONGO_URL)$find()
issue_comment=mongo(collection="issue_comment",url=MONGO_URL)$find()
message=mongo(collection="message",url=MONGO_URL)$find()
event=mongo(collection="event",url=MONGO_URL)$find()
con_commit=mongo(collection="commit", url=MONGO_URL)
commit=con_commit$find()
tag=mongo(collection="tag",url=MONGO_URL)$find()

# Collect all people_id from the related data above
mcci=c()
mtoi=c()
for(x in unique(message$cc_ids)) {
  for(y in unique(x)) {
    mcci=c(mcci, toString(y))
  }
}
for(x in unique(message$to_ids)) {
  for(y in unique(x)) {
    mtoi=c(mtoi, toString(y))
  }
}
tmpid = c(issue$creator_id, issue$reporter_id, issue_comment$author_id,
           message$from_id, mcci, mtoi,
           event$author_id,
           commit$author_id, commit$committer_id,
           tag$tagger_id)
people_id=unique(tmpid)
# people_id=na.omit(people_id)
people_id=people_id[!is.na(people_id)]

# Load data of people from csv exported from mongodb
people_orig=read.csv("http://user.informatik.uni-goettingen.de/~chenfeng.zhu/data/people.csv")
# str_replace_all(people_orig$X_id,"ObjectId((","")
people_orig$X_id = gsub('[)]', '', gsub('ObjectId[(]', '', people_orig$X_id))

# classified by people's information (email, name, username)
p_cat=cbind(people_orig, category=1)
p_cat[,5]=1
for(i in 1:nrow(p_cat)) {
  if (grepl("[Dd]ev",paste(p_cat[i,2],p_cat[i,3],p_cat[i,4]))==TRUE) {
    p_cat[i,5]=3
  } else if (grepl("user",paste(p_cat[i,2],p_cat[i,3],p_cat[i,4]))==TRUE) {
    p_cat[i,5]=2
  }
}
for(i in 1:nrow(p_cat)) {
  # Exception
  if (TRUE) {
  } else if (grepl("edevil",p_cat[i,4])==TRUE) {
    p_cat[i,5]=1
  } else if (grepl("gnoremac",p_cat[i,4])==TRUE) {
    p_cat[i,5]=1
  } else if (grepl("devaraj",p_cat[i,4])==TRUE) {
    p_cat[i,5]=1
  } else if (grepl("devaki.vamsi",p_cat[i,4])==TRUE) {
    p_cat[i,5]=1
  } else if (grepl("devesh.srivastava",p_cat[i,4])==TRUE) {
    p_cat[i,5]=1
  } else if (grepl("devkonar",p_cat[i,4])==TRUE) {
    p_cat[i,5]=1
  } else if (grepl("mahadev",p_cat[i,4])==TRUE) {
    p_cat[i,5]=1
  } else if (grepl("Savithadi",p_cat[i,4])==TRUE) {
    p_cat[i,5]=1
  } else if (grepl("sudev.ac",p_cat[i,4])==TRUE) {
    p_cat[i,5]=1
  } else if (grepl("[Vv]aibhav.[Dd]evekar",p_cat[i,4])==TRUE) {
    p_cat[i,5]=1
  } else if (grepl("akvadrako",p_cat[i,4])==TRUE) {
    p_cat[i,5]=1
  }
}


########################
# Data Collection
########################

# Base
datatable=as.data.frame(people_id)

# commit relative
commit_auth=data.frame(table(commit$author_id))
colnames(commit_auth)=c("people_id","commit_auth_total")
commit_commit=data.frame(table(commit$committer_id))
colnames(commit_commit)=c("people_id","commit_commit_total")
datatable=merge(datatable,commit_auth,by.x="people_id",by.y="people_id",all.x=TRUE)
datatable=merge(datatable,commit_commit,by.x="people_id",by.y="people_id",all.x=TRUE)
datatable[is.na(datatable)]=0

# issue relative
issue_create=data.frame(table(issue$creator_id))
colnames(issue_create)=c("people_id","issue_create_total")
issue_report=data.frame(table(issue$reporter_id))
colnames(issue_report)=c("people_id","issue_report_total")
datatable=merge(datatable,issue_create,by.x="people_id",by.y="people_id",all.x=TRUE)
datatable=merge(datatable,issue_report,by.x="people_id",by.y="people_id",all.x=TRUE)
issue_comm=data.frame(table(issue_comment$author_id))
colnames(issue_comm)=c("people_id","issue_comment_total")
datatable=merge(datatable,issue_comm,by.x="people_id",by.y="people_id",all.x=TRUE)
datatable[is.na(datatable)]=0

# event relative
event_auth=data.frame(table(event$author_id))
colnames(event_auth)=c("people_id","event_auth_total")
datatable=merge(datatable,event_auth,by.x="people_id",by.y="people_id",all.x=TRUE)
datatable[is.na(datatable)]=0

# tag relative
tag_tag=data.frame(table(tag$tagger_id))
colnames(tag_tag)=c("people_id","tag_tag_total")
datatable=merge(datatable,tag_tag,by.x="people_id",by.y="people_id",all.x=TRUE)
datatable[is.na(datatable)]=0

# email relative
message_from=data.frame(table(message$from_id))
colnames(message_from)=c("people_id","message_from_total")
datatable=merge(datatable,message_from,by.x="people_id",by.y="people_id",all.x=TRUE)
datatable[is.na(datatable)]=0


########################
# Data Transformation
########################

# Merge information into matrix
userdatatable=merge(datatable,p_cat,by.x="people_id",by.y="X_id",all.x=TRUE)
userdatatable[is.na(userdatatable)]=0
# userdatatable[2,]
# whether considering other types of participants
x=userdatatable
for(i in 1:nrow(userdatatable)) {
  if ((userdatatable[i,2]+userdatatable[i,3]+userdatatable[i,4]+userdatatable[i,5])!=0) {
    # userdatatable[i,13]=4
    # print(userdatatable[i,])
  }
}
x=userdatatable[userdatatable[,13]!="1",]
for(i in 1:nrow(x)) {
  if (x[i,13]=="4") {
    x[i,13]="1"
  }
}
# x=userdatatable[userdatatable[,13]!=0,]

# Write into a csv file
# write.csv(userdatatable, file="~/public_html/data/ds_dragon.csv")


########################
# Data Analysis
########################

# Create training data
#train=rbind(matrix(x$commit_auth_total,ncol = 7), matrix(x$commit_commit_total,ncol = 7), matrix(x$issue_create_total,ncol = 7), matrix(x$issue_report_total,ncol = 7), matrix(x$event_auth_total,ncol = 7), matrix(x$issue_comment_total,ncol = 7), matrix(x$message_from_total,ncol = 7))
#train=rbind(matrix(x$issue_create_total,ncol = 3), matrix(x$issue_report_total,ncol = 3),matrix(x$commit_commit_total,ncol = 3))
#train=rbind(matrix(x$issue_report_total,ncol = 2),matrix(x$issue_comment_total,ncol = 2))

##############
# 1. k-means
#train=rbind(matrix(x$commit_auth_total,ncol = 7), matrix(x$commit_commit_total,ncol = 7), matrix(x$issue_create_total,ncol = 7), matrix(x$issue_report_total,ncol = 7), matrix(x$event_auth_total,ncol = 7), matrix(x$issue_comment_total,ncol = 7), matrix(x$message_from_total,ncol = 7))
# 3
x=userdatatable
train=rbind(matrix(x$commit_auth_total,ncol = 7), matrix(x$commit_commit_total,ncol = 7), matrix(x$issue_create_total,ncol = 7), matrix(x$issue_report_total,ncol = 7), matrix(x$event_auth_total,ncol = 7), matrix(x$issue_comment_total,ncol = 7), matrix(x$message_from_total,ncol = 7))
prediction1=kmeans(train,3)
real=matrix(x$category)
prediction2=matrix(prediction1$cluster)
prediction2=prediction2[-c(1,2),]
prediction2=matrix(prediction2)
#prediction2=prediction2[,1]+1
confusionMatrix(real,prediction2)

# 2 for 3 attributes
#x=datatable[datatable[,13]!="1",]
x=userdatatable[userdatatable[,13]!="1",]
#train=rbind(matrix(x$commit_auth_total,ncol = 7), matrix(x$commit_commit_total,ncol = 7), matrix(x$issue_create_total,ncol = 7), matrix(x$issue_report_total,ncol = 7), matrix(x$event_auth_total,ncol = 7), matrix(x$issue_comment_total,ncol = 7), matrix(x$message_from_total,ncol = 7))
train=rbind(matrix(x$issue_create_total,ncol = 3), matrix(x$issue_report_total,ncol = 3),matrix(x$commit_commit_total,ncol = 3))
prediction1=kmeans(train,2)
real=matrix(x$category)
prediction2=matrix(prediction1$cluster)
#prediction2=prediction2[-c(1,1),]
prediction2=matrix(prediction2)
prediction2=prediction2[,1]+1
confusionMatrix(real,prediction2)


# 2 for 7 attributes
#x=datatable[datatable[,13]!="1",]
x=userdatatable[userdatatable[,13]!="1",]
train=rbind(matrix(x$commit_auth_total,ncol = 7), matrix(x$commit_commit_total,ncol = 7), matrix(x$issue_create_total,ncol = 7), matrix(x$issue_report_total,ncol = 7), matrix(x$event_auth_total,ncol = 7), matrix(x$issue_comment_total,ncol = 7), matrix(x$message_from_total,ncol = 7))
#train=rbind(matrix(x$issue_create_total,ncol = 3), matrix(x$issue_report_total,ncol = 3),matrix(x$commit_commit_total,ncol = 3))
prediction1=kmeans(train,2)
real=matrix(x$category)
prediction2=matrix(prediction1$cluster)
prediction2=prediction2[-c(1,1),]
prediction2=matrix(prediction2)
prediction2=prediction2[,1]+1
confusionMatrix(real,prediction2)


##############
# 2. ctree
x=userdatatable
y = x[sample(nrow(x)),]
#y=rbind(matrix(x$commit_auth_total,ncol = 7), matrix(x$commit_commit_total,ncol = 7), matrix(x$issue_create_total,ncol = 7), matrix(x$issue_report_total,ncol = 7), matrix(x$event_auth_total,ncol = 7), matrix(x$issue_comment_total,ncol = 7), matrix(x$message_from_total,ncol = 7))
y=rbind(matrix(x$commit_auth_total,ncol = 8), matrix(x$commit_commit_total,ncol = 8), matrix(x$issue_create_total,ncol = 8), matrix(x$issue_report_total,ncol = 8), matrix(x$event_auth_total,ncol = 8), matrix(x$issue_comment_total,ncol = 8), matrix(x$message_from_total,ncol = 8),matrix(x$category,ncol = 8))
#train=rbind(matrix(x$commit_auth_total,ncol = 7), matrix(x$commit_commit_total,ncol = 7), matrix(x$issue_create_total,ncol = 7), matrix(x$issue_report_total,ncol = 7), matrix(x$event_auth_total,ncol = 7), matrix(x$issue_comment_total,ncol = 7), matrix(x$message_from_total,ncol = 7))
y=x
y[,1]       <- NULL
y[,9]       <- NULL
y[,9]       <- NULL
y[,9]       <- NULL
y$category <- as.factor(y$category)
y = y[sample(nrow(y)),]
train=y[1:3000,]
test=y[3000:4583,]
model_ctree <- ctree(category ~ .,data = train)
plot(model_ctree)
pred_ctree=predict(model_ctree, test)
confusionMatrix(test$category,pred_ctree)

##############
# 3.naiveBayes
x=userdatatable
y = x[sample(nrow(x)),]
#y=rbind(matrix(x$commit_auth_total,ncol = 7), matrix(x$commit_commit_total,ncol = 7), matrix(x$issue_create_total,ncol = 7), matrix(x$issue_report_total,ncol = 7), matrix(x$event_auth_total,ncol = 7), matrix(x$issue_comment_total,ncol = 7), matrix(x$message_from_total,ncol = 7))
y=rbind(matrix(x$commit_auth_total,ncol = 8), matrix(x$commit_commit_total,ncol = 8), matrix(x$issue_create_total,ncol = 8), matrix(x$issue_report_total,ncol = 8), matrix(x$event_auth_total,ncol = 8), matrix(x$issue_comment_total,ncol = 8), matrix(x$message_from_total,ncol = 8),matrix(x$category,ncol = 8))
#train=rbind(matrix(x$commit_auth_total,ncol = 7), matrix(x$commit_commit_total,ncol = 7), matrix(x$issue_create_total,ncol = 7), matrix(x$issue_report_total,ncol = 7), matrix(x$event_auth_total,ncol = 7), matrix(x$issue_comment_total,ncol = 7), matrix(x$message_from_total,ncol = 7))
y=x
y[,1]       <- NULL
y[,9]       <- NULL
y[,9]       <- NULL
y[,9]       <- NULL
y$category <- as.factor(y$category)
y = y[sample(nrow(y)),]
train=y[1:3000,]
test=y[3000:4583,]
model_naiveBayes=naiveBayes(category ~ ., data = train)
pred_naiveBayes=predict(model_naiveBayes, test)
#table(pred_naiveBayes, test$Species)
confusionMatrix(pred_naiveBayes,test$category)




##############
# Others
# Create the training set and test set
d=userdatatable[(userdatatable[,2]+userdatatable[,3]+userdatatable[,4]+userdatatable[,5])!=0,]
nrow(d)
excercisedata=cbind(d[,2:5],d[,13])
colnames(excercisedata)[5]="category"
train_row <- sample(nrow(excercisedata), 400)
training_set <- excercisedata[train_row,]
test_set <- excercisedata[-train_row,]

# 1. naive Bayes classifier
# nb_all <- naiveBayes(training_set[,2:5], training_set[,13])
nb_all <- naiveBayes(training_set[,1:4], training_set[,5])
table(predict(nb_all, training_set[,1:4]), training_set[,5], dnn = list('predict','actual'))

# 2. decision tree
ct_all <- ctree(category ~ .,data = training_set)
table(predict(ct_all, training_set[,1:4]), training_set[,5])
plot(ct_all)
confusionMatrix(test_set$category, predict(ct_all, test_set[,1:4]))

# Evaluate the results
# naive bayes
nb_ptrain <- predict(nb_all, training_set[,1:4])
nb_ptest <- predict(nb_all, test_set[,1:4])
table(nb_ptrain, training_set[,5], dnn = list('predict','actual'))
table(nb_ptest, test_set[,5], dnn = list('predict','actual'))
# decision tree
ct_ptrain <- predict(ct_all, training_set[,1:4])
ct_ptest <- predict(ct_all, test_set[,1:4])
table(ct_ptrain, training_set[,5])
table(ct_ptest, test_set[,5])


########################
# References
########################

# http://smartshark2.informatik.uni-goettingen.de/documentation/
# https://docs.mongodb.com/manual


########################
# Useful Commands
########################

con_project = mongo(collection = "project", url = MONGO_URL)
project = con_project$find()

con_file = mongo(collection = "file", url = MONGO_URL)
file = con_file$find()

con_fileaction = mongo(collection = "file_action", url = MONGO_URL)
fileaction = con_fileaction$find()

con_people = mongo(collection = "people", url = MONGO_URL)

people = con_people$find()

people = con_people$find('{"username":"zookeeper-user"}')

con_commit = mongo(collection="commit", url=MONGO_URL)
commits = con_commit$find()
commits = con_commit$find(fields='{"_id":1, "committer_date":1}')
print(paste("latest commit:", max(commits$committer_date)))
latest_commit_id = commits[which.max(commits$committer_date),1]

con_codeentitystate = mongo(collection="code_entity_state", url=MONGO_URL)
query_str = paste('{"commit_id":{"$oid": "',latest_commit_id,'"}}', sep="")
code_entities = con_codeentitystate$find(query_str)

