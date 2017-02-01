# Install and load libraries
install.packages("mongolite")
install.packages("dplyr")
install.packages("forecast")

library(mongolite)
library(dplyr)
library(forecast)

# URL for connecting to the remote MongoDB hosted at the GWDG
MONGO_URL = "mongodb://group8:AASfGdv6@141.5.113.177:27017/smartshark_test"

# Create connection to event collection
connection_issue <- mongo(collection = "issue", url = MONGO_URL)

# Fetch all data from the event collection into a data frame
issue <- connection_issue$find()

# Remove the time
date <- format(issue$created_at, format = "%Y-%m-%d")

# Remove missing value
date <- date[complete.cases(date)]

# Count number of issues in each day and put it in a data frame
df <- as.data.frame(table(date))

# Convert the date into the Date type
df$date <- as.Date(df$date, "%Y-%m-%d")

# Count number of issues in each month
df <- df %>%
  mutate(month = format(date, "%m"), year = format(date, "%Y")) %>%
  group_by(year, month) %>%
  summarise(total = sum(Freq))

# Create time series
df.ts <- ts(df$total, frequency = 12, start = c(2008, 6))

# Clean the data
df.ts <- tsclean(df.ts)

# Training and testing dataset. Spare the last 2 years for testing
trainData.ts <- window(df.ts, c(2008, 6), c(2014, 12))
testData.ts <- window(df.ts, 2015, c(2016, 12))

plot(
  trainData.ts,
  xlab = "Year",
  ylab = "Number of issues",
  xaxp = c(2008, 2015, 7),
  main = "Number of issues from June 2008 to December 2014"
)

# Decompose data
trainData.decompose <- stl(trainData.ts, s.window = "periodic")
plot(trainData.decompose, main = "Decomposed Data", xaxp = c(2008, 2015, 7))

# Build ARIMA model
model <- auto.arima(trainData.ts, D = 1)

# Forecast the next 24 months
prediction <- forecast(model, h = 24)

# Plot the prediction and the Test Data
plot(
  prediction,
  xlab = "Year",
  ylab = "Number of issues",
  xaxp = c(2008, 2018, 10),
  main = "Prediction in year 2015 and 2016"
)
lines(testData.ts, col = "red")
legend(
  "bottomleft",
  c("Training data", "Testing data", "Prediction"),
  lty = c(1, 1),
  lwd = c(1, 1),
  col = c("black", "red", "blue"),
  cex = 0.75,
  bty = "n"
)

#------------------------------------------------------------------#
# Build model for all data
model <- auto.arima(df.ts, D = 1)

# Forecast the next 12 months
prediction <- forecast(model, h = 12)

# Plot the prediction and the Test Data
plot(
  prediction,
  xlab = "Year",
  ylab = "Number of issues",
  xaxp = c(2008, 2018, 10),
  main = "Prediction in year 2017"
)
legend(
  "bottomleft",
  c("Previous data", "Prediction"),
  lty = c(1, 1),
  lwd = c(1, 1),
  col = c("black", "blue"),
  cex = 0.75,
  bty = "n"
)