#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

# Carregando Bibliotecas
library(shiny)
library(htmltools)

### SHINY UI ##############################################################################################################################################
ui <- bootstrapPage(
  
  titlePanel(NULL,windowTitle="Levantamento da Necessidade de Creches na Região Metropolitana do Recife"),
  

# HTML(r"(
#             
#          <style>
#         table, th, td {
#           padding: 10 px;
#           text-align:left;
#           background-color:white;
#         
#         }
#         div,p {
#           padding: 0 px;
#           font-size:25px;
#           text-align:left;
#           color:#0F2759;
#           background-color:white;
#         }
#         </style>
#         <div>
#                     <img src="seplag50.png" align="right" width="30%"/>
#                     <img src="ig50.png" align="left" width="10%"/>
#         </div>
#         <div>
#                       <p style = "text-align:center; font-size:15px" >
#                         Núcleo de Ciências de Dados                                                    <br>
#                         <small>Nota Técnica - Levantamento da Necessidade de Creches na RMR</small>
#                       </p>
#         </div>
#         <div>
#                       <p>
#      
#      <br>
#                       </p>
#         </div>     
# )"),
                       div(htmltools::includeHTML("www/creches_app.html"))
                      

                    )
### SHINY SERVER ###

server = function(input, output, session) {}  





#runApp(shinyApp(ui, server), launch.browser = TRUE)
shinyApp(ui, server)

#library(rsconnect)
#deployApp(account="vac-lshtm")


