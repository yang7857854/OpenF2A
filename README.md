# OpenF2A
This repository presents a fully coupled framework (OpenF2A) for dynamic analysis of floating offshore wind turbines and wind-wave hybrid concepts. OpenF2A is developed by Professor Yang Yang in the Ningbo University (https://hyxy.nbu.edu.cn/info/2692/51105.htm) based on OpenFAST (https://github.com/OpenFAST/openfast) and ANSYS-AQWA, which acts as a continuous work of F2A (https://github.com/yang7857854/F2A) that has already been extensively used in the design of floating offshore wind turbines and wind-wave hybrid concepts.

OpenFAST v4.0.0 is used in the development of OpenF2A. The later versions of OpenF2A will be renamed following the version of OpenFAST, to be simply identified by users which version of OpenFAST case files should be used in OpenF2A simulations. For instance, the OpenF2A will be named as OpenF2A v4.0.0 if OpenFAST v4.0.0 is used.

OpenF2A is not only valid for dynamic analysis of floating offshore wind turbine, but also valid for wind-wave integrated floating energy systems by simply modelling the WECs in AQWA. We have provided an example of wind-wave IFES model based on the 5MW OC4DeepCwind concept in this repository.

# Regression tests
The OC4 DeepCwind model used in the publication (Yang, Y., Yu, J., Bashir, M., & Li, C. (2026). Development and applicability of a novel fully coupled framework for floating wind energy systems. Ocean Engineering, 354, 124900.) is added in the RegTests of this repository. The free decay and turbulent wind combined with still water load scenarios are included. In addition, the OpenFAST cases are included for comparison.

Moreover, the wind-wave IFES model is included. We will also add the model files for OC3 Hywind, OOStar 10MW, VolturnUS-S 15MW in the coming days.

Because of size limitation of GitHub, we cannot upload wind data files along with the regression tests. You will need to generate the required wind data files by running TurbSim that can be found in the release. 
Due to the same reason, we shared the CAD files of the platform model instead of ANSYS Workbench project files. 

# Use OpenF2A
OpenF2A is essentially a dynamic link library invoked by AQWA for calculation of external loads on platform. Therefore, we need to run time-domain simulations and activate the external DLL flag in AQWA.
In the provided examples, we need to examine AQWA in the command promote window. The options of AQWA simulations are defined in the basic input file with an extension of “.dat”. I believe relevant users would be familiar with it. 

If you want to use OpenF2A in Workbench, you will need to put OpenF2A associated files into the workbench case folder. Just ensure that relevant path of OpenFAST model files and OpenF2A input is consistent with that as provided. 

Examples of how to use OpenF2A are given in the simple introduction document. 

# Note for the optional DLL
We have provided another DLL of the OpenF2A with the name "Option". This DLL is the one used to conduct simulations in the publication (Yang, Y., Yu, J., Bashir, M., & Li, C. (2026). Development and applicability of a novel fully coupled framework for floating wind energy systems. Ocean Engineering, 354, 124900.)

In this version of OpenF2A, the platform DOFs were solved together with other DOFs to consider the influence of the platform on the tower dynamics. The restoring forces and added mass effects are considered as platform loads. In the AugMat matrix, these values are included in the platform associated terms, including platform-tower coupled terms. 

This is different from what has been implemented in previous versions of OpenF2A. The advantage is that the influence of the platform on tower dynamics will be examined properly to correct the tower’s natural frequency. However, there is a disadvantage of this implementation that the numerical stability of the simulation cannot be guaranteed, which is mainly attributed to the platform acceleration transferred from AQWA. The backward difference of velocity is used to represent platform acceleration, which is valid for most cases, but the inevitable numerical error diminishes the numerical stability. 

This DLL works perfectly for the OC4 DeepCwind model, but it becomes invalid for the OC3 Hywind model. The same implementation strategy between OpenFAST and WEC-Sim is valid for the Hywind spar model, which has been confirmed by our team. The plausible reason is that WEC-Sim can directly transfer the accelerations, rather than using the time difference of velocity like AQWA. Therefore, we suspect that the numerical error of platform acceleration is the main reason for the numerical instability of the hybrid simulation framework OpenF2A for some models. 

In order to ensure the generalization of the OpenF2A interface, we have to release the source code of OpenF2A without correcting the tower dynamics. The platform dynamics can be accurately examined using the current tool. We hope that this code can be improved to address the problem of numerical instability shortly by us or someone else. 

# References
The following publications are for your information when you need a reference to cite if OpenF2A is useful in your research. The 1st and 8th publications listed below are recommended the most. We are grateful for your acknowledgement by citing our research. More suitable references can be found on my google scholar website https://scholar.google.com/citations?user=frTAwNQAAAAJ&hl=zh-CN.

1. Yang, Y., Yu, J., Bashir, M., & Li, C. (2026). Development and applicability of a novel fully coupled framework for floating wind energy systems. Ocean Engineering, 354, 124900
2. Hu, G., Ding, J., Lai, Y., He, C., Zhang, Z., Liu, W., ... & Yang, Y. (2026). Coupled dynamic behavior of a floating offshore wind turbine integrated with flapping-type-wave energy converters under wind-wave misalignment conditions. Ocean Engineering, 353, 124816.
3. Liu, W., ZHANG, Z., Lai, Y., Hu, G., Yu, J., Li, C., ... & Yang, Y. (2026). Stability and power performance of a floating wind-current energy system under tidal turbine operating mode variations. Energy, 140209.
4. Nie, D., Li, S., Yan, Y., Lou, Y., Yin, J., Hao, J., ... & Yang, Y. (2025). Structural analysis of a 15 MW floating offshore wind turbine platform based on a novel fully-coupled framework. Ocean Engineering, 342, 123057.
5. Yin, J., Fan, Y., Bashir, M., Nie, D., Lai, Y., Ding, J., ... & Yang, Y. (2025). Development of a hybrid deep learning model with HHO algorithm for dynamic response prediction of wind-wave integrated floating energy systems. Ocean Engineering, 340, 122394.
6. Ding, J., Yang, Y., Yu, J., Bashir, M., Ma, L., Li, C., & Li, S. (2024). Fully coupled dynamic responses of barge-type integrated floating wind-wave energy systems with different WEC layouts. Ocean Engineering, 313, 119453.
7. Yang, Y., Shi, Z., Fu, J., Ma, L., Yu, J., Fang, F., ... & Yang, W. (2023). Effects of tidal turbine number on the performance of a 10 MW-class semi-submersible integrated floating wind-current system. Energy, 285, 128789.
8. Yang, Y., Bashir, M., Michailides, C., Li, C., & Wang, J. (2020). Development and application of an aero-hydro-servo-elastic coupling framework for analysis of floating offshore wind turbines. Renewable Energy, 161, 606-625.

# Contact
Please do not hesitate to contact me regarding any issues with OpenF2A by sending emails to: yangyang1@nbu.edu.cn.  

We hope OpenF2A will contribute to your research, which is the greatest desire in our heart. 

Kind regards,

Yang Yang @ Ningbo University

9-March-2026




