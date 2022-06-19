;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; GNU GENERAL PUBLIC LICENSE ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;  Module for calculation of ARID using GIS and weather data
;;  Based on modified parts of:
;;  Land model
;;  Copyright (C) 2019 Andreas Angourakis (andros.spica@gmail.com)
;;  available at https://www.github.com/Andros-Spica/indus-village-model
;;  implementing the Soil Water Balance model from Wallach et al. 2006 'Working with dynamic crop models' (p. 24-28 and p. 138-144).
;;  This implementation uses parts of the Weather model to simulate input variables (i.e., temperature, solar radiation, precipitation, evapotranspiration)
;;
;;  This program is free software: you can redistribute it and/or modify
;;  it under the terms of the GNU General Public License as published by
;;  the Free Software Foundation, either version 3 of the License, or
;;  (at your option) any later version.
;;
;;  This program is distributed in the hope that it will be useful,
;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;  GNU General Public License for more details.
;;
;;  You should have received a copy of the GNU General Public License
;;  along with this program.  If not, see <http://www.gnu.org/licenses/>.

extensions [ gis ]

;;;;;;;;;;;;;;;;;
;;;;; BREEDS ;;;;
;;;;;;;;;;;;;;;;;

breed [ sites site ]

breed [ flowHolders flowHolder ]

;;;;;;;;;;;;;;;;;
;;; VARIABLES ;;;
;;;;;;;;;;;;;;;;;

globals
[
  patchesWithElevationData
  noElevationDataTag
  maxElevation

  width
  height

  ;;; GIS data holders
  sitesData_EMIII-MMIA
  sitesData_MMIB
  elevationData
  riversData

  ;;; variables
  maxFlowAccumulation
]

sites-own
[
  name
  siteType
  period
]

patches-own
[
  elevation ; elevation above sea level [m]

  flow_direction        ; the numeric code for the (main) direction of flow or
                        ; drainage within the land unit.
                        ; Following Jenson & Domingue (1988) convention:
                        ; NW = 64,   N = 128,        NE = 1,
                        ; W = 32,     <CENTRE>,   E = 2,
                        ; SW = 16,     S = 8,          SE = 4

  flow_receive          ; Boolean variable stating whether or not the land unit receives
                        ; the flow of a neighbour.

  flow_accumulation     ; the amount of flow units accumulated in the land unit.
                        ; A Flow unit is the volume of runoff water flowing from one land unit
                        ; to another (assumed constant and without losses).
  flow_accumulationState ; the state of the land unit regarding the calculation of flow
                        ; accumulation (auxiliary variable).

  isRiver
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; SETUP ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup

  clear-all

  create-map

  ; --- display & output handling ------------------------

  display-flows

  display-rivers

  refresh-view

  ; -- time -------------------------------------

  reset-ticks

end

to create-map

  load-gis  ;; load in the GIS data

  set-world-dimensions ;; set world dimensions according to GIS data

  setup-patches ;; use GIS data to set patch variables

  setup-sites ;; create site agents with properties from sitesData

end

to set-world-dimensions

  ;;; for better performance, we take a multiple fraction of the dimensions of elevationData,
  ;;; so that patches will get average values or more regular sets of pixels

  let patchXpixelScale 0.1 ;;; keep it less than 0.25
  let pixelExtentMargin 50

  set width ceiling ((pixelExtentMargin + gis:width-of elevationData) * patchXpixelScale)
  set height ceiling ((pixelExtentMargin + gis:height-of elevationData) * patchXpixelScale)

  resize-world 0 width 0 height

  set-patch-size 5

end

to setup-patches

  setup-elevation

  setup-flows

  setup-rivers

end


to setup-elevation

  gis:apply-raster elevationData elevation

  set patchesWithElevationData patches with [(elevation <= 0) or (elevation >= 0)]

  ;;; replace NaN values added by the gis extension with noElevationDataTag, so it does not generate problems after
  set noElevationDataTag -9999
  ask patches with [not ((elevation <= 0) or (elevation >= 0))] [ set elevation noElevationDataTag ]

  set maxElevation max [elevation] of patchesWithElevationData

end

to setup-flows

  fill-sinks

  set-flow-directions

  set-flow-accumulations

  ; set maximum flow accumulation as a reference
  set maxFlowAccumulation max [flow_accumulation] of patchesWithElevationData

end

;=======================================================================================================
;;; START of algorithms based on:
;;; Huang, P., Lee, K.T. A simple depression-filling method for raster and irregular elevation datasets.
;;; J Earth Syst Sci 124, 1653–1665 (2015). https://doi.org/10.1007/s12040-015-0641-2
;=======================================================================================================

to fill-sinks

  while [ count patchesWithElevationData with [is-sink] > 0 ]
  [
    ask patchesWithElevationData with [is-sink]
    [
      ;print (word "before: " elevation)
      set elevation [elevation] of min-one-of neighbors [elevation] + 1E-1
      ; the scale of this "small number" (1E-1) regulates how fast will be the calculation
      ; and how distorted will be the depressless DEM
      ;print (word "after: " elevation)
    ]
  ]

end

to-report is-sink ; ego = patch

  let thisPatch self

  report (not is-at-edge) and (elevation <= min [elevation] of neighbors with [elevation > noElevationDataTag])

end

;=======================================================================================================
;;; END of algorithms based on:
;;; Huang, P., Lee, K.T. A simple depression-filling method for raster and irregular elevation datasets.
;;; J Earth Syst Sci 124, 1653–1665 (2015). https://doi.org/10.1007/s12040-015-0641-2
;=======================================================================================================
;=======================================================================================================
;;; START of algorithms based on:
;;; Jenson, S. K., & Domingue, J. O. (1988).
;;; Extracting topographic structure from digital elevation data for geographic information system analysis.
;;; Photogrammetric engineering and remote sensing, 54(11), 1593-1600.
;;; ===BUT used elsewhere, such as in the algorithms based on:
;;; Huang, P., Lee, K.T. A simple depression-filling method for raster and irregular elevation datasets.
;;; J Earth Syst Sci 124, 1653–1665 (2015). https://doi.org/10.1007/s12040-015-0641-2
;=======================================================================================================

to-report get-drop-from [ aPatch ] ; ego = patch

  ; "Distance- weighted drop is calculated by subtracting the neighbor’s value from the center cell’s value
  ; and dividing by the distance from the center cell, √2 for a corner cell and one for a noncorner cell." (p. 1594)

  report ([elevation] of aPatch - elevation) / (distance aPatch)

end

to-report is-at-edge ; ego = patch

  report any? neighbors with [elevation = noElevationDataTag]

end

to-report has-flow-direction-code ; ego = patch

  if (member? flow_direction [ 1 2 4 8 16 32 64 128 ]) [ report true ]

  report false

end

to-report flow-direction-is [ centralPatch ]

  if (flow_direction = get-flow-direction-encoding ([pxcor] of centralPatch - pxcor) ([pycor] of centralPatch - pycor))
  [ report true ]

  report false

end

to-report get-flow-direction-encoding [ x y ]

  if (x = -1 and y = -1) [ report 16 ] ; Southwest
  if (x = -1 and y = 0) [ report 32 ]  ; West
  if (x = -1 and y = 1) [ report 64 ]  ; Northwest

  if (x = 0 and y = -1) [ report 8 ]   ; South
  if (x = 0 and y = 1) [ report 128 ]  ; North

  if (x = 1 and y = -1) [ report 4 ]   ; Southeast
  if (x = 1 and y = 0) [ report 2 ]    ; East
  if (x = 1 and y = 1) [ report 1 ]    ; Northeast

end

to-report get-patch-in-flow-direction [ neighborEncoding ] ; ego = patch

  ; 64 128 1
  ; 32  x  2
  ; 16  8  4

  if (neighborEncoding = 16) [ report patch (pxcor - 1) (pycor - 1) ]
  if (neighborEncoding = 32) [ report patch (pxcor - 1) (pycor) ]
  if (neighborEncoding = 64) [ report patch (pxcor - 1) (pycor + 1) ]

  if (neighborEncoding = 8) [ report patch (pxcor) (pycor - 1) ]
  if (neighborEncoding = 128) [ report patch (pxcor) (pycor + 1) ]

  if (neighborEncoding = 4) [ report patch (pxcor + 1) (pycor - 1) ]
  if (neighborEncoding = 2) [ report patch (pxcor + 1) (pycor) ]
  if (neighborEncoding = 1) [ report patch (pxcor + 1) (pycor + 1) ]

  report nobody

end

to-report flow-direction-is-loop ; ego = patch

  let thisPatch self
  let dowstreamPatch get-patch-in-flow-direction flow_direction
  ;print (word "thisPatch: " thisPatch "dowstreamPatch: " dowstreamPatch)

  if (dowstreamPatch != nobody)
  [ report [flow-direction-is thisPatch] of dowstreamPatch ]

  report false

end

to set-flow-directions

  ask patchesWithElevationData
  [
    ifelse (is-at-edge)
    [
      ifelse ( pxcor = min-pxcor )
      [ set flow_direction 32 ] ; west
      [
        ifelse ( pxcor = max-pxcor )
        [ set flow_direction 2 ] ; east
        [
          ifelse ( pycor = min-pycor )
          [ set flow_direction 8 ] ; south
          [ set flow_direction 128 ] ; north
        ]
      ]
    ]
    [
      set-flow-direction
    ]
  ]

end

to set-flow-direction ; ego = patch

  let thisPatch self

  let downstreamPatch max-one-of neighbors with [elevation > noElevationDataTag] [get-drop-from thisPatch]
  set flow_direction get-flow-direction-encoding ([pxcor] of downstreamPatch - pxcor) ([pycor] of downstreamPatch - pycor)

end

to set-flow-accumulations

  ; From Jenson, S. K., & Domingue, J. O. (1988), p. 1594
  ; "FLOW ACCUMULATION DATA SET
  ; The third procedure of the conditioning phase makes use of the flow direction data set to create the flow accumulation data set,
  ; where each cell is assigned a value equal to the number of cells that flow to it (O’Callaghan and Mark, 1984).
  ; Cells having a flow accumulation value of zero (to which no other cells flow) generally correspond to the pattern of ridges.
  ; Because all cells in a depressionless DEM have a path to the data set edge, the pattern formed by highlighting cells
  ; with values higher than some threshold delineates a fully connected drainage network."

  ; identify patches that receive flow and those that do not (this makes the next step much easier)
  ask patchesWithElevationData
  [
    set flow_receive false
    set flow_accumulationState "start"
    ;set pcolor red
  ]

  ask patchesWithElevationData with [has-flow-direction-code]
  [
    let patchInFlowDirection get-patch-in-flow-direction flow_direction
    if (patchInFlowDirection != nobody)
    [
      ask patchInFlowDirection
      [
        set flow_receive true
        set flow_accumulationState "pending"
        ;set pcolor yellow
      ]
    ]
  ]

  let maxIterations 100000 ; just as a safety measure, to avoid infinite loop
  while [count patchesWithElevationData with [flow_accumulationState = "pending" and not flow-direction-is-loop] > 0 and maxIterations > 0 and count patchesWithElevationData with [flow_accumulationState = "start"] > 0 ]
  [
    ask one-of patchesWithElevationData with [flow_accumulationState = "start"]
    [
      let downstreamPatch get-patch-in-flow-direction flow_direction
      let nextFlow_accumulation flow_accumulation + 1

      set flow_accumulationState "done"
      ;set pcolor orange

      if (downstreamPatch != nobody)
      [
        ask downstreamPatch
        [
          set flow_accumulation flow_accumulation + nextFlow_accumulation
          if (count neighbors with [
            elevation > noElevationDataTag and
            get-patch-in-flow-direction flow_direction = downstreamPatch and
            (flow_accumulationState = "pending" or flow_accumulationState = "start")
            ] = 0
          )
          [
            set flow_accumulationState "start"
            ;set pcolor red
          ]
        ]
      ]
    ]

    set maxIterations maxIterations - 1
  ]

end

;=======================================================================================================
;;; END of algorithms based on:
;;; Jenson, S. K., & Domingue, J. O. (1988).
;;; Extracting topographic structure from digital elevation data for geographic information system analysis.
;;; Photogrammetric engineering and remote sensing, 54(11), 1593-1600.
;;; ===BUT used in the algorithms based on:
;;; Huang P C and Lee K T 2015
;;; A simple depression-filling method for raster and irregular elevation datasets
;;; J. Earth Syst. Sci. 124 1653–65
;=======================================================================================================

to setup-rivers

  ;print gis:feature-list-of riversData
  ask patchesWithElevationData
  [
    set isRiver gis:intersects? riversData self
  ]

end

to setup-sites

  ;;; gis extension will re-use a site, if it was already created in a position,
  ;;; and modify any values we already set.
  ;;; In order to avoid this, we cannot use gis:create-turtles-from-points

  let datasetPeriod "EMIII-MMIA"
  foreach gis:feature-list-of sitesData_EMIII-MMIA
  [
    vectorFeature ->

    create-site-from-feature vectorFeature datasetPeriod
  ]

  set datasetPeriod "MMIB"
  foreach gis:feature-list-of sitesData_MMIB
  [
    vectorFeature ->

    create-site-from-feature vectorFeature datasetPeriod
  ]

end

to create-site-from-feature [ vectorFeature datasetPeriod ]

  let coordTuple gis:location-of (first (first (gis:vertex-lists-of vectorFeature)))
  let featureName gis:property-value vectorFeature "NAME"
  let featureType gis:property-value vectorFeature "TYPE"

  let long item 0 coordTuple
  let lat item 1 coordTuple

  create-sites 1
  [
    setxy long lat
    set name featureName
    set siteType featureType
    set period datasetPeriod

    set shape "dot"
  ]

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; DISPLAY ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to display-rivers

  gis:set-drawing-color blue
  gis:draw riversData 1

end

to refresh-view

  ask patchesWithElevationData [ display-elevation ]

end

to display-elevation

  let elevationGradient 100 + (155 * (elevation / maxElevation))
  set pcolor rgb (elevationGradient - 100) elevationGradient 0

end

to display-flows

  if (not any? flowHolders)
  [
    ask patchesWithElevationData [ sprout-flowHolders 1 [ set hidden? true ] ]
  ]

  ask patchesWithElevationData
  [
    let flow_directionHere flow_direction
    let nextPatchInFlow get-patch-in-flow-direction flow_direction
    if (not [elevation > noElevationDataTag] of nextPatchInFlow) [ set nextPatchInFlow nobody ]
    let flow_accumulationHere flow_accumulation

    ask one-of flowHolders-here
    [
      ifelse (nextPatchInFlow != nobody)
      [
        if (link-with one-of [flowHolders-here] of nextPatchInFlow = nobody)
        [ create-link-with one-of [flowHolders-here] of nextPatchInFlow ]

        ask link-with one-of [flowHolders-here] of nextPatchInFlow
        [
          set hidden? false
          let multiplier 1E100 ^ (1 - flow_accumulationHere / (max [flow_accumulation] of patchesWithElevationData)) / 1E100
          set color 92 + (5 * multiplier)
          set thickness 0.4 * ( 1 - ((color - 92) / 5))
        ]
      ]
      [
        set hidden? false
        let multiplier 1E100 ^ (1 - flow_accumulationHere / (max [flow_accumulation] of patchesWithElevationData)) / 1E100
        set color 92 + (5 * multiplier)
        if (color <= 97) [ set shape "line half" ]
        if (color < 95) [ set shape "line half 1" ]
        if (color < 93) [ set shape "line half 2" ]
        set heading get-angle-in-flow-direction flow_direction
      ]
    ]
  ]

end

to-report get-angle-in-flow-direction [ neighborEncoding ]

  ; 64 128 1
  ; 32  x  2
  ; 16  8  4

  if (neighborEncoding = 16) [ report 225 ]
  if (neighborEncoding = 32) [ report 270 ]
  if (neighborEncoding = 64) [ report 315 ]

  if (neighborEncoding = 8) [ report 180 ]
  if (neighborEncoding = 128) [ report 0 ]

  if (neighborEncoding = 4) [ report 135 ]
  if (neighborEncoding = 2) [ report 90 ]
  if (neighborEncoding = 1) [ report 45 ]

  report nobody

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; GIS DATA LOAD AND PREPARATION ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to load-gis

  ; Load all of our datasets
  set sitesData_EMIII-MMIA gis:load-dataset "data/Cretedata/EMIII_MMIAsites.shp"
  set sitesData_MMIB gis:load-dataset "data/Cretedata/MMIBsites.shp"

  set elevationData gis:load-dataset "data/Cretedata/dem15.asc"
  set riversData gis:load-dataset "data/Cretedata/rivers.shp"

  ; Set the world envelope to the union of all of our dataset's envelopes ; NOT NEEDED IF USING DEM?
  gis:set-world-envelope (gis:envelope-of elevationData)

end
@#$#@#$#@
GRAPHICS-WINDOW
200
10
1438
794
-1
-1
5.0
1
10
1
1
1
0
1
1
1
0
245
0
154
0
0
1
ticks
30.0

BUTTON
69
22
124
55
NIL
setup
NIL
1
T
OBSERVER
NIL
1
NIL
NIL
1

BUTTON
26
68
166
101
export world
export-world \"data/terrainWithFlows/BlockC_module2_flows world.csv\"
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
28
111
166
144
import world
clear-all\nimport-world \"data/terrainWithFlows/BlockC_module2_flows world.csv\"
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

line half 1
true
0
Line -7500403 true 150 0 150 300
Rectangle -7500403 true true 135 0 165 150

line half 2
true
0
Line -7500403 true 150 0 150 300
Rectangle -7500403 true true 120 0 180 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2190"/>
    <metric>T</metric>
    <metric>T_max</metric>
    <metric>T_min</metric>
    <metric>RAIN</metric>
    <metric>solarRadiation</metric>
    <metric>ETr</metric>
    <metric>mean [WATp] of patches</metric>
    <metric>mean [ARID] of patches</metric>
    <metric>mean [biomass] of patches with [position crop typesOfCrops = 0]</metric>
    <metric>mean [biomass] of patches with [position crop typesOfCrops = 1]</metric>
    <metric>mean [yield] of patches with [position crop typesOfCrops = 0]</metric>
    <metric>mean [yield] of patches with [position crop typesOfCrops = 1]</metric>
    <enumeratedValueSet variable="precipitation_daily-cum_rate2_yearly-mean">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="CO2-mean">
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="solar_annual-min">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="precipitation_daily-cum_rate2_yearly-sd">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="CO2-daily-fluctuation">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="precipitation_yearly-sd">
      <value value="130"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="solar_annual-max">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="precipitation_daily-cum_plateau-value_yearly-sd">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="precipitation_daily-cum_n-sample">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="precipitation_daily-cum_inflection1_yearly-sd">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="CO2-annual-deviation">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="precipitation_daily-cum_max-sample-size">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="precipitation_daily-cum_inflection2_yearly-sd">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="precipitation_daily-cum_inflection2_yearly-mean">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="temperature_mean-daily-fluctuation">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="temperature_annual-min-at-2m">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="solar_mean-daily-fluctuation">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="temperature_daily-lower-deviation">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="temperature_annual-max-at-2m">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="temperature_daily-upper-deviation">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="end-simulation-in-tick">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="precipitation_yearly-mean">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="precipitation_daily-cum_inflection1_yearly-mean">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="precipitation_daily-cum_rate1_yearly-mean">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-mode">
      <value value="&quot;crops&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="precipitation_daily-cum_plateau-value_yearly-mean">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="precipitation_daily-cum_rate1_yearly-sd">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="type-of-experiment">
      <value value="&quot;user-defined&quot;"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
