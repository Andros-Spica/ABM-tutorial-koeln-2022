# Archaeological ABM at Cologne: from concept to application
Materials for the session organised by the [CoDArchLab](http://archaeoinformatik.uni-koeln.de/) in the Institute of Archaeology at University of Cologne (20/6/2022).

This exercise introduces some Agent-based modelling (ABM) techniques used in archaeology. More specifically, it covers the prototyping of a conceptual model into a working simulation model, the 'refactoring' of code (cleaning, restructuring, optimising), the re-use of published model parts and algorithms, the exploration of alternative designs, and the use of geographic and archaeological data to apply the model to the context of a specific case study.

This tutorial uses [NetLogo](https://ccl.northwestern.edu/netlogo/), a flexible well-established modelling platform that is known for its relative low-level entry requirements in terms of programming experience. It has been particularly used in social sciences and ecology, both for research and pedagogic purposes.

## Table of contents

- [Archaeological ABM at Cologne: from concept to application](#archaeological-abm-at-cologne-from-concept-to-application)
  - [Table of contents](#table-of-contents)
  - [Preparation](#preparation)
  - [Introduction](#introduction)
    - [Mathematical models](#mathematical-models)
    - [ABM main concepts](#abm-main-concepts)
    - [ABM in archaeology](#abm-in-archaeology)
    - [SES framework](#ses-framework)
    - [Modelling 'steps'](#modelling-steps)
    - [References](#references)
  - [Tutorial](#tutorial)
    - [Block A](#block-a)
      - [Definition of domain/phenomenon/question](#definition-of-domainphenomenonquestion)
      - [Conceptual model](#conceptual-model)
      - [NOTE #1: classic models as reference](#note-1-classic-models-as-reference)
      - [Getting to know NetLogo](#getting-to-know-netlogo)
      - [NOTE #2: other platforms/languages](#note-2-other-platformslanguages)
      - [Prototyping](#prototyping)
    - [Block B](#block-b)
      - [Verification-refactoring cycle](#verification-refactoring-cycle)
      - [Modularity and re-use](#modularity-and-re-use)
      - [NOTE #3: NetLogo Modelling Commons, CoMSES, NASSA](#note-3-netlogo-modelling-commons-comses-nassa)
      - [Exploring alternative and additional designs](#exploring-alternative-and-additional-designs)
    - [Block C](#block-c)
      - [Integrating spatial data as input](#integrating-spatial-data-as-input)
      - [Integrating time-series data as input](#integrating-time-series-data-as-input)
      - [NOTE #4: degrees of model calibration](#note-4-degrees-of-model-calibration)
      - [Formating and exporting output data](#formating-and-exporting-output-data)
      - [Strategies for model 'validation'](#strategies-for-model-validation)

## Preparation

To prepare for the tutorial, you only need to:

- Download and install the latest version of NetLogo. The system-specific installation files are found here: https://ccl.northwestern.edu/netlogo/download.shtml
- Download or 'clone' the contents of this repository into a local folder. Select ![Code](images/Code-button.png) in the top right of the repository page in GitHub, and choose one of the options given.

---
---
## Introduction

---
### Mathematical models

: mechanism- vs. pattern-driven models

---
### ABM main concepts


---
### ABM in archaeology

---
### SES framework

the behaviour-environment balance

---
### Modelling 'steps'



---
### References

**_Introductions to ABM in archaeology_**

> Romanowska, Iza. 2021. Agent-Based Modeling for Archaeology. Electronic. SFI Press. https://doi.org/10.37911/9781947864382.

> Romanowska, Iza, Stefani A. Crabtree, Kathryn Harris, and Benjamin Davies. 2019. ‘Agent-Based Modeling for Archaeologists: Part 1 of 3’. Advances in Archaeological Practice 7 (2): 178–84. https://doi.org/10.1017/aap.2019.6.

> Davies, Benjamin, Iza Romanowska, Kathryn Harris, and Stefani A. Crabtree. 2019. ‘Combining Geographic Information Systems and Agent-Based Models in Archaeology: Part 2 of 3’. Advances in Archaeological Practice 7 (2): 185–93. https://doi.org/10.1017/aap.2019.5.

> Crabtree, Stefani A., Kathryn Harris, Benjamin Davies, and Iza Romanowska. 2019. ‘Outreach in Archaeology with Agent-Based Modeling: Part 3 of 3’. Advances in Archaeological Practice 7 (2): 194–202. https://doi.org/10.1017/aap.2019.4.

> Graham, Shawn, Neha Gupta, Jolene Smith, Andreas Angourakis, Andrew Reinhard, Ellen Ellenberger, Zack Batist, et al. n.d. ‘4.4 Artificial Intelligence in Digital Archaeology’. In The Open Digital Archaeology Textbook. Ottawa: ECampusOntario. https://o-date.github.io/draft/book/artificial-intelligence-in-digital-archaeology.html.

> Breitenecker, Felix, Martin Bicher, and Gabriel Wurzer. 2015. ‘Agent-Based Simulation in Archaeology: A Characterization’. In Agent-Based Modeling and Simulation in Archaeology, edited by Gabriel Wurzer, Kerstin Kowarik, and Hans Reschreiter, 53–76. Springer, Cham. https://doi.org/10.1007/978-3-319-00008-4_3.

> Cegielski, Wendy H., and J. Daniel Rogers. 2016. ‘Rethinking the Role of Agent-Based Modeling in Archaeology’. Journal of Anthropological Archaeology 41 (March): 283–98. https://doi.org/10.1016/J.JAA.2016.01.009.


**_Application examples of ABM in archaeology_**

> Rubio Campillo, Xavier, Jose María Cela, and Francesc Xavier Hernàndez Cardona. 2012. ‘Simulating Archaeologists? Using Agent-Based Modelling to Improve Battlefield Excavations’. Journal of Archaeological Science 39 (2): 347–56. https://doi.org/10.1016/j.jas.2011.09.020.

> Premo, L. S. 2006. ‘Agent-Based Models as Behavioral Laboratories for Evolutionary Anthropological Research’. Arizona Anthropologist 17: 91–113.

> Madella, Marco, Bernardo Rondelli, Carla Lancelotti, Andrea L. Balbo, Débora Zurro, Xavier Rubio Campillo, and Sebastian Stride. 2014. ‘Introduction to Simulating the Past’. Journal of Archaeological Method and Theory 21 (2): 251–57. https://doi.org/10.1007/s10816-014-9209-8.

> Angourakis, Andreas, Matthieu Salpeteur, Verònica Martínez Ferreras, Josep Maria Gurt Esparraguera, Verònica Martínez Ferreras, and Josep Maria Gurt Esparraguera. 2017. ‘The Nice Musical Chairs Model: Exploring the Role of Competition and Cooperation Between Farming and Herding in the Formation of Land Use Patterns in Arid Afro-Eurasia’. Journal of Archaeological Method and Theory 24 (4): 1177–1202. https://doi.org/10.1007/s10816-016-9309-8.


**_On the ODD protocol_**

> Grimm, Volker, Uta Berger, Finn Bastiansen, Sigrunn Eliassen, Vincent Ginot, Jarl Giske, John Goss-Custard, et al. 2006. ‘A Standard Protocol for Describing Individual-Based and Agent-Based Models’. Ecological Modelling 198 (1–2): 115–26. https://doi.org/10.1016/J.ECOLMODEL.2006.04.023.

> Grimm, Volker, Uta Berger, Donald L. DeAngelis, J. Gary Polhill, Jarl Giske, and Steven F. Railsback. 2010. ‘The ODD Protocol: A Review and First Update’. Ecological Modelling 221 (23): 2760–68. https://doi.org/10.1016/J.ECOLMODEL.2010.08.019.

> Müller, Birgit, Friedrich Bohn, Gunnar Dreßler, Jürgen Groeneveld, Christian Klassert, Romina Martin, Maja Schlüter, Jule Schulze, Hanna Weise, and Nina Schwarz. 2013. ‘Describing Human Decisions in Agent-Based Models – ODD + D, an Extension of the ODD Protocol’. Environmental Modelling & Software 48 (October): 37–48. https://doi.org/10.1016/J.ENVSOFT.2013.06.003.

---
---
## Tutorial

!!!INTRO

Case study: 

**Settlement interaction and the emergence of hierarchical settlement structures in Prepalatial south-central Crete** (Paliou & Bevan 2016)

!!! Brief Summary and mention of regression approach used in paper

**Main Reference**

> Paliou, Eleftheria, and Andrew Bevan. 2016. ‘Evolving Settlement Patterns, Spatial Interaction and the Socio-Political Organisation of Late Prepalatial South-Central Crete’. Journal of Anthropological Archaeology 42 (June): 184–97. https://doi.org/10.1016/j.jaa.2016.04.006.

**Useful complementary references**

> Angourakis, Andreas, Jennifer Bates, Jean-Philippe Baudouin, Alena Giesche, Joanna R. Walker, M. Cemre Ustunkaya, Nathan Wright, Ravindra Nath Singh, and Cameron A. Petrie. 2022. ‘Weather, Land and Crops in the Indus Village Model: A Simulation Framework for Crop Dynamics under Environmental Variability and Climate Change in the Indus Civilisation’. Quaternary 5 (2): 25. https://doi.org/10.3390/quat5020025.

> Wilkinson, Tony J., John H. Christiansen, Jason Alik Ur, M. Widell, and Mark R. Altaweel. 2007. ‘Urbanization within a Dynamic Environment: Modeling Bronze Age Communities in Upper Mesopotamia’. American Anthropologist 109 (1): 52–68. https://doi.org/10.1525/aa.2007.109.1.52.

---

### Block A

#### Definition of domain/phenomenon/question

#### Conceptual model 

#### NOTE #1: classic models as reference

#### Getting to know NetLogo

#### NOTE #2: other platforms/languages

#### Prototyping

---
### Block B

#### Verification-refactoring cycle

#### Modularity and re-use 

#### NOTE #3: NetLogo Modelling Commons, CoMSES, NASSA

#### Exploring alternative and additional designs

---
### Block C

#### Integrating spatial data as input

The NetLogo default installation includes an extension to support GIS that can be used by adding the following to the first section of your script:

```
extensions [ gis ]
```

This extension allows you to perform a variety of GIS operations and to connect patch and turtle behaviour to data expressed in GIS files, supporting both vector and raster. The description of its contents can be found here: https://ccl.northwestern.edu/netlogo/docs/gis.html

In this tutorial, we will only reference a few of the aspects of GIS in NetLogo. You will find useful 

#### Integrating time-series data as input

#### NOTE #4: degrees of model calibration

#### Formating and exporting output data

#### Strategies for model 'validation'

