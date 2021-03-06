assign_polygons <- function(shape, new_polygons)
  
{
  originalPoints <- gCentroid(shape, byid = TRUE)
  shape@data$CENTROIX <- originalPoints$x
  shape@data$CENTROIY <- originalPoints$y
  shape@data$key_orig <- paste(originalPoints$x, originalPoints$y, sep = "_")

  new_points <- new_polygons[[1]]
  vector_length <- length(shape)

  new_polygons2 <- new_polygons[[2]]
  polygonPoints <- gCentroid(new_polygons2, byid = TRUE)
  s_poly <- SpatialPolygonsDataFrame(new_polygons2, as.data.frame(coordinates(new_polygons2)))
  s_poly$key_new <- paste(s_poly@data$V1, s_poly@data$V2, sep = "_")

  # Define these vectors, used in the assignment loop.
  closestSiteVec <- vector(mode = "numeric", length = vector_length)
  minDistVec <- vector(mode = "numeric", length = vector_length)
  takenVec <- vector(mode = "numeric", length = vector_length)
  takenVecIndex <- integer(vector_length)

  shape_areas <- rgeos::gArea(shape, byid = TRUE)

  for (i in 1:vector_length)
  {
    distVec <- spDistsN1(originalPoints, new_points[i], longlat = FALSE)
    minDistVec[i] <- min(distVec)

    if (i > 1)
    {

      distVec[takenVecIndex] <- NA
      closestSiteVec[i] <- which.min(distVec)

    } else
    {
      closestSiteVec[i] <- which.min(distVec)
    }

    takenVec[i] <- which.min(distVec)
    takenVecIndex <- takenVec[takenVec > 0]

    costmatrix <- spDists(originalPoints, new_points, longlat = FALSE)
    colnames(costmatrix) <- paste(s_poly@data$V1, s_poly@data$V2, sep = "_")
    rownames(costmatrix) <- paste(originalPoints@coords[, 1], originalPoints@coords[, 2], sep = "_")
    hungarian_costmin <- hungarian_cc(costmatrix)
  }

  costmin_locs <- as.data.frame(which(hungarian_costmin == 1, arr.ind = TRUE))
  costmin_locs$key_new <- colnames(costmatrix)[costmin_locs$col]
  costmin_locs$key_orig <- rownames(costmatrix)[costmin_locs$row]
  # costmin_locs$CENTROIDX <- as.numeric(strsplit(costmin_locs$key_new,"_")[[1]][1])
  # costmin_locs$CENTROIDy <- as.numeric(strsplit(costmin_locs$key_new,"_")[[1]][1])

  FinalTable <- costmin_locs

  combi <- sp::merge(shape@data, FinalTable, by.x = "key_orig")
  combi2 <- sp::merge(s_poly, combi, by.x = "key_new")
  return(combi2)
    
}
