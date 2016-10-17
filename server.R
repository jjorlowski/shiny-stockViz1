library(data.table)
library(RODBC)
library(shiny)
library(ggplot2)
library(rsconnect)
library(scales)
SQLProdDM.Datamart_master <- odbcDriverConnect("driver={SQL Server};
                                                server=SQLPRODDM\\DATAMART;
                                                database=master;
                                                trusted_connection=true")
DWHCarProd.DataWarehouseCar_CarvanaDWHS <- odbcDriverConnect("driver={SQL Server};
                                                              server=dwhcarprod\\datawarehousecar;
                                                              database=CarvanaDWHS;
                                                              trusted_connection=true")
getStockEvents <- function(StockNumber){
  EventsQuery <- paste("SELECT stke.StockEventTypeID, stke.EventDateTime
                       FROM CarvanaDM.dbo.tblStockEvent stke
                       WHERE stke.StockNumber=",StockNumber,sep="")
  Events <- sqlQuery(SQLProdDM.Datamart_master,EventsQuery)
}

getEventsForSimilarMM <- function(StockNumber,MinDate){
  #MinDate makes sure we just get event history while primary stock number was on-site 
  SimilarMMQuery <- paste("SELECT stke.StockNumber, stke.StockEventTypeID, stke.EventDateTime
                          FROM CarvanaDM.dbo.tblStockEvent stke
                          JOIN CarvanaDM.dbo.tblStock stk
                          ON stk.StockNumber=stke.StockNumber
                          WHERE stk.MakeModelID=(SELECT MakeModelID
                          FROM CarvanaDM.dbo.tblStock
                          WHERE StockNumber=",StockNumber,")
                          AND	stke.EventDateTime >'",MinDate,"' ",sep="")
  SimilarMMEvents <- sqlQuery(SQLProdDM.Datamart_master,SimilarMMQuery)
}

getLocks <- function(StockNumber){
  LocksQuery <- paste("SELECT p.RowLoadedDateTime as LockTime, p.IsDeletedFromAzure as LockExpired
                      FROM CarvanaDM.dbo.tblPurchase p
                      WHERE p.StockNumber=",StockNumber,sep="")
  Locks <- sqlQuery(SQLProdDM.Datamart_master,LocksQuery)
}

getVehicleInfo <- function(StockNumber){
  InfoQuery <- paste("SELECT *
                     FROM dw.DimVehicle dv
                     WHERE dv.StockNumber=",StockNumber,sep="")
  Info <- sqlQuery(DWHCarProd.DataWarehouseCar_CarvanaDWHS,InfoQuery)
}

function(input,output){
  Events <- reactive(geStockEvents(input$StockNumber))
  SimilarMMEvents <- reactive(getEventsForSimilarMM(input$StockNumber),'SomeDate')##Logic to get first date goes here
  Locks <- reactive(getLocks(input$StockNumber))
  Info <- reactive(getVehicleInfo(input$StockNumber))
  
  #Outputs
  
  output$mainPlot <- "foo"
  output$vehicleInfo <- "bar"
}
