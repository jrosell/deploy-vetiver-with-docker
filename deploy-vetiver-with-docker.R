library(tidyverse)
library(tidymodels)
library(vetiver)
library(pins)
options(readr.show_col_types = FALSE) 

# First create the vetiver model and prepare the docker deployument

superbowl_ads_raw <- read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2021/2021-03-02/youtube.csv')

superbowl_ads <-
  superbowl_ads_raw %>%
  select(funny:animals, like_count) %>%
  na.omit()

rf_spec <- rand_forest(mode = "regression")
rf_form <- like_count ~ .

rf_fit <-
    workflow(rf_form, rf_spec) %>%
    fit(superbowl_ads)


v <- vetiver_model(rf_fit, "superbowlads")

invisible(!dir.exists("models") && dir.create("models"))
board <- board_folder("models")
vetiver_pin_write(board, v)

vetiver_prepare_docker(
  board, 
  "superbowlads", 
  docker_args = list(port = 8080)
)

# Then, build the image
# docker build -t superbowlads .

# Once the image is builded, you can run the container with the models volume:
# docker run --name superbowlads -v $(pwd)/models:/opt/ml/models -p 8080:8080 superbowlads

# Then you can make predictions:

new_ads <- superbowl_ads %>% 
    select(-like_count)
endpoint <- vetiver_endpoint("http://0.0.0.0:8080/predict")
predict(endpoint, new_ads)

# Stop all containers
# docker stop $(docker ps -a -q)

# To debug: 
# docker run --rm -it docker-v $(pwd)/models:/opt/ml/models --entrypoint bash 

# Optional: Remove containers and images
# docker ps -a | grep "superbowlads" | awk '{print $1}' | xargs docker rm
# docker images -a | grep "superbowlads" | awk '{print $1":"$2}' | xargs docker rmi