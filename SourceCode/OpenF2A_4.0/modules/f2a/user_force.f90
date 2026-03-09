!******************************************************************************
SUBROUTINE USER_FORCE(MODE,I_CONTROL,R_CONTROL,NSTRUC,TIME,TIMESTEP,STAGE,POSITION,VELOCITY,COG,FORCE,ADDMASS,ERRORFLAG)

!DECLARATION TO MAKE USER_FORCE PUBLIC WITH UN-MANGLED NAME 

!DEC$ attributes dllexport , STDCALL , ALIAS : "USER_FORCE" :: user_force

!DEC$ ATTRIBUTES REFERENCE :: I_CONTROL, R_CONTROL
!DEC$ ATTRIBUTES REFERENCE :: POSITION, VELOCITY, COG, FORCE, ADDMASS
!DEC$ ATTRIBUTES REFERENCE :: MODE, NSTRUC, TIME, TIMESTEP, STAGE
!DEC$ ATTRIBUTES REFERENCE :: ERRORFLAG
!***************************************************************
! This DLL is called by AQWA for external force calculation
! It is developed by Yang Yang(a PDRA at LJMU) on 18/03/2019
!***************************************************************
! This DLL is revised to employ Aerodyn v15 for aerodynamic force calculation.
! Revision date: 01-05-2019.
! By: Yang Yang, PhD from Unversity of Shanghai for Science and Technology.
! All copyrights reserved. For any kind of use please contact Y.Yang for authorization.
! Email: 15216702797@163.com .or. y.yang@ljmu.ac.uk
!***************************************************************
! Revision for considering overhang of rotor
! Date: 22-10-2019
! By: Yang Yang
!***************************************************************
! Revision for coupling with FAST
! Date: 22-10-2019
! By: Yang Yang
!***************************************************************
! Revision: The DLL is modified to incoprate FAST with AQWA
! By: Yang Yang
! Date: 10-March-2020
!***************************************************************
! Revision: The DLL is improved to incorprate AeroDyn15 for use in modelling
!           Integrated floating offshore renewable energy systems(IFORES)
!
!
!
!


USE Precision
USE AQWAinFAST

USE F2AModules
USE F2ASubs

IMPLICIT NONE


INTEGER MODE, NSTRUC, STAGE, ERRORFLAG
REAL TIME, TIMESTEP
INTEGER, DIMENSION (100) :: I_CONTROL
REAL, DIMENSION (100) :: R_CONTROL
REAL, DIMENSION (3,NSTRUC) :: COG
REAL, DIMENSION (6,NSTRUC) :: POSITION, VELOCITY, FORCE
REAL, DIMENSION (6,6,NSTRUC) :: ADDMASS
!
INTEGER, DIMENSION (2) :: INITP

!
! Input Parameter Description:
!
! MODE(Int)     - 0 = Initialisation. This routine is called once with mode 0
!                     before the simulation. All parameters are as described
!                     below except for STAGE, which is undefined. FORCES and
!                     ADDMASS are assumed undefined on exit.
!                     IERR if set to > 0 on exit will cause
!                     the simulation to stop.
!
!                 1 = Called during the simulation. FORCE/ADDMASS output expected.
! 
!                99 = Termination. This routine is called once with mode 99
!                     at the end of the simulation.
!
! I_CONTROL(100)- User-defined integer control parameters input in .DAT file.
! R_CONTROL(100)- User-defined real control parameters input in .DAT file.
!
! NSTRUC(Int)   - Number of structures in the simulation
!
! TIME          - The current time (see STAGE below)
!
! TIMESTEP      - The timestep size (DT, see STAGE below)
!
! STAGE(Int)    - The stage of the integration scheme. AQWA time integration is
!                 based on a 2-stage predictor corrector method. This routine is
!                 therefore called twice at each timestep, once with STAGE=1 and
!                 once with STAGE=2. On stage 2 the position and velocity are
!                 predictions of the position and velocity at TIME+DT. 
!                 e.g. if the initial time is 0.0 and the step 1.0 seconds then
!                 calls are as follows for the 1st 3 integration steps:
!
!                 CALL USER_FORCE(.....,TIME=0.0,TIMESTEP=1.0,STAGE=1 ...)
!                 CALL USER_FORCE(.....,TIME=0.0,TIMESTEP=1.0,STAGE=2 ...)
!                 CALL USER_FORCE(.....,TIME=1.0,TIMESTEP=1.0,STAGE=1 ...)
!                 CALL USER_FORCE(.....,TIME=1.0,TIMESTEP=1.0,STAGE=2 ...)
!                 CALL USER_FORCE(.....,TIME=2.0,TIMESTEP=1.0,STAGE=1 ...)
!                 CALL USER_FORCE(.....,TIME=2.0,TIMESTEP=1.0,STAGE=2 ...)
!
! COG(3,NSTRUC) - Position of the Centre of Gravity in the Definition axes. 
!
! POSITION(6,NSTRUC) - Position of the structure in the FRA - angles in radians
!
! VELOCITY(6,NSTRUC) - Velocity of the structure in the FRA 
!                      angular velocity in rad/s
!
!
! Output Parameter Description:
!
! FORCE(6,NSTRUC) - Force on the Centre of gravity of the structure. NB: these
!                   forces are applied in the Fixed Reference axis e.g.
!                   the surge(X) force is ALWAYS IN THE SAME DIRECTION i.e. in
!                   the direction of the X fixed reference axis.
!
! ADDMASS(6,6,NSTRUC)
!                 - Added mass matrix for each structure. As the value of the
!                   acceleration is dependent on FORCES, this matrix may be used
!                   to apply inertia type forces to the structure. This mass
!                   will be added to the total added mass of the structure at
!                   each timestep at each stage.
!
! ERRORFLAG       - Error flag. The program will abort at any time if this
!                   error flag is non-zero. The values of the error flag will
!                   be output in the abort message.

!------------------------------------------------------------------------
! MODE=0 - Initialise any summing variables/open/create files.
!          This mode is executed once before the simulation begins.
!------------------------------------------------------------------------
! Define variables for the calculation

  ! Local variables


  integer              :: iread         ! Temp indicator for reading
  real                 :: Mot(6)        ! Current motion of the platform
  real                 :: Vel(6)        ! Current velocity of the platform

  integer              :: i,j           ! Indicator in calculation
  integer              :: iTemp         ! Indicator in calculation
  real                 :: TempVec       ! Temporary vector


! Time and date information that will be output in the result file.


  
!---------------------------------------------------------------------
! Body of F2A
!---------------------------------------------------------------------
IF (MODE.EQ.0) THEN
   
! Default inputs (shall be meaningless)   
   !INITP(1)=R_CONTROL(3)
   !INITP(2)=R_CONTROL(4)

! Get the current time and date that will be output in the result files.
   call getDateTime()
! Write F2A notice
   call WrtNoticeOpenF2A()  
! Get the primary inputs from the default file "InputFileForFAST2AQWA.txt"
   call getOpenF2AInput()

       

continue

!------------------------------------------------------------------------
! MODE=1 - On-going - calculation of forces/mass
!------------------------------------------------------------------------
ELSEIF (MODE.EQ.1) THEN

!ERRORFLAG = 0
       
! Initialize force and added mass.
      FORCE = 0.0
      ADDMASS = 0.0
! Set Motion and COG
       do iTurbine = 1,NumWTs
          Mot = POSITION (:,IdStr(iTurbine))
          Vel = VELOCITY (:,IdStr(iTurbine))
          CoGPtfm = COG(:,IdStr(iTurbine))
         
! Get tower-base loads mass information
          call getTwrBsLds (TIME,STAGE,TIMESTEP,Mot,Vel,CoGPtfm,MODE)
          
! Convert the loads referred with the local reference coordinate system to the loads referred with the inerial system
	      call ConvertPtfLds (POSITION (4:6,IdStr(iTurbine)),CoGPtfm,iTurbine)	

          do iTemp = 1,6    ! Apply the loads due to wind turbines
             FORCE(iTemp,IdStr(iTurbine)) = AddedPtfmLds(iTemp)
             !ADDMASS(iTemp,iTemp,IdStr(iTurbine)) = AddedWTMass(iTemp)
          enddo   ! end loop of six load components
           !write(UnOuTAM,'(F10.3,6(ES15.6))') TIME,(AddedWTMass(iTemp),iTemp=1,6)
	   enddo ! end loop of multiple wind turbines

   
! Write results     

! Done coupling
     
!------------------------------------------------------------------------
! MODE=99 - Termination - Output/print any summaries required/Close Files
!           This mode is executed once at the end of the simulation
!------------------------------------------------------------------------

ELSEIF (MODE.EQ.99) THEN

! Done, terminate the analysis

   call  FAST (TIME,NumWTs,0.5*TIMESTEP,STAGE,PriFile(1),POSITION (:,1),VELOCITY (:,1),VELOCITY (:,1),MODE) ! terminate OpenFAST, only the value of Mode will be used 
   
   
!------------------------------------------------------------------------
! MODE# ERROR - OUTPUT ERROR MESSAGE
!------------------------------------------------------------------------

ELSE	

ENDIF
RETURN

END SUBROUTINE USER_FORCE

