Module F2AModules
    
    USE                             Precision
  
! UnIO variables
    integer,save :: UnPIn   = 10001                           ! I/O unit of the primary input file (InputFileForFAST2AQWA.txt).
    integer,save :: UnFstIn = 10002                           ! I/O unit of the FAST primary input file (xxx.fst).
    integer,save :: UnOuTF  = 10003                           ! I/O unit of the output file containing the platform loads
    integer,save :: UnOuTM  = 10004                           ! I/O unit of the output file containing the platform motions
    integer,save :: UnOuTD  = 10005                           ! I/O unit of the output file containing the relative displacement bwtween orignial point and CoG
    integer,save :: UnOuTUF  = 10006                          ! I/O unit of the output file containing the stiffness force due in userforce
    integer,save :: UnOuTED  = 10007                          ! I/O unit of the output file containing the stiffness force due in elastodyn
    real,save :: gAcceScale      = 9.80665                     ! Gravitational acceleration, m/s^2
    real,save :: RhoSea      = 1025                      ! Density of sea water, kg/m^3
    real,save :: PI      = 3.1415926                     ! Parameter PI
    real,save :: R2D     = 57.295780                     ! Factor to convert radians to degrees.
    real,save :: RPS2RPM = 9.5492966                     ! Factor to convert radians per second(rps) to revolutions per minute (rpm).
! Input variables defined in InputFileForFAST2AQWA.txt
    !character (len=1024),save :: Prifile       ! - Primary input file for FAST
    logical,save         :: CouplingFlag  ! - Flag of the coupling interface
    integer,save         :: PtfmRestoreFlag  ! - Flag of considering the restoring forces on platform when predicting wind turbine dynamics in OpenFAST
    integer,save         :: IndexTwrStr   ! - Index of the structure connecting to the rotor directly.
! date and time
    character(len=8)  :: Currdate       ! Current date
    character(len=10) :: CurrTime       ! Current time
    character(len=50) :: Time_Date      ! String of date and time 
! local variables
    real,save            :: DT_FAST                ! Time step in FAST (Unit: s)
    real,save            :: PtfmVol0              ! Displaced volume of water when the body is in its undisplaced position (m^3)
    real,save            :: PtfmCOBxt             ! The xt offset of the center of buoyancy (COB) from (0,0) (meters) 
    real,save            :: PtfmCOByt             ! The yt offset of the center of buoyancy (COB) from (0,0) (meters) 
    integer,save         :: RatioStep              ! Ratio of timestep in AQWA to time step in FAST
    real,save            :: deltaD(3)              ! Motion difference between the local and the orignial frames
    real,save            :: VelLast1(6),VelLast2(6)             ! Velocity at last time step
    real,save            :: AcceLast1(6),AcceLast2(6)             ! Acceleration at last time step
    real,save            :: AddedPtfmLds(6)        ! Platform loads due to the turbine
    real,save            :: PtfmStffMat(6,6)         ! Platform restoring stiffness including the contribution of mooring system and hydrostatic
    real,save            :: PtfmAddedMassMat(6,6)         ! Platform added mass at infinite frequency
    real,save            :: OffsetLoads(6)         ! Platform offset loads

    
! additional stiffness
    !real,save            :: AddStffMat(6,6) ! additional stiffness matrix used to correct the mooring system with a delta design configuration
    !real,save            :: AddForce(6) = 0     ! additional force
! Multi-turbine
   integer(4), save :: NumWTs                                  ! Number of wind turbines
   integer(4), save :: iTurbine                                ! Index in loop of multiple wind turbines
   character(len=1024), allocatable,save :: Prifile(:)      ! Primay input file of OpenFAST
   integer, allocatable, save            :: IdStr(:)        ! Index of structure modelled in AQWA that connects to the ith wind turbine 
   real, allocatable, save               :: OffsetWT(:,:)   ! Offset of the ith tind turbine's reference coordinate system  
   real, save                            :: CoGPtfm(3)     ! Platform's CoG
! ============================================================    
end module F2AModules
    
    ! Yang: Add a module for AQWA invokation 
MODULE AQWAinFAST

   ! This MODULE stores the variables passing through the DLL of AQWA    

USE                             Precision

REAL (Reki)          ,SAVE :: PtfmMotAQWA(6)                    ! Platform motion at the current time step
REAL (Reki)          ,SAVE :: PtfmVelAQWA(6)                    ! Platform velocity at the current time step
REAL (Reki)          ,SAVE :: PtfmAcceAQWA(6)                   ! Platform acceleration at the current time step
REAL (Reki)          ,SAVE :: PtfmMomAQWA(3)                    ! Platform moment due to tower base forces 
REAL (Reki)          ,SAVE :: PtfmFrcAQWA(3)                    ! Platform forces due to tower base forces 
REAL (Reki)          ,SAVE :: LenTwrBs2Ref                      ! length between tower base to platform reference
REAL (Reki)          ,SAVE :: PtfmRef_AQWA                      ! platform reference point
REAL (Reki)          ,SAVE :: PtfmRestLoads(6)       ! Platform loads on due to the restoring stiffness
REAL (Reki)          ,SAVE :: AddedWTMass (6)          ! Added mass due to rotor, tower and nacelle


END MODULE AQWAinFAST