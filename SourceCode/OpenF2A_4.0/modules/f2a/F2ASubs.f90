MODULE F2ASubs
    
USE Precision

	CONTAINS
! ========================================================================================
! SUBROUTINE ConvertPtfLds
! Purpose: Convert the loads referred with the local reference coordinate system to the
!          loads referred with the inerial system
! ========================================================================================   
  SUBROUTINE ConvertPtfLds (Rots,CoG,iTurbine)
  
  !USE TurbConf, ONLY: rZT0zt     ! distance between tower-base and platform reference point
  USE AQWAinFAST
  USE F2AModules,ONLY:AddedPtfmLds,OffsetWT
  
  
  IMPLICIT NONE
  
  real :: LocalLoads(6)               ! Temporary forces and moments
  real :: InertialLDs(6)              ! Inertial loads
  real :: Rots(3)                     ! Rotations of the local frame
  real :: CoG(3)                         ! CoG of the platform
  real :: z1(3),z2(3),z3(3)           ! Coordinate vector of platform reference frame
  real :: a1(3),a2(3),a3(3)           ! Coordinate vector of inertial frame
  real :: TransMat(3,3)               ! Transformation matrix
  real :: TransMat2(3,3)              ! Transformation matrix
  real :: armV                        ! Vertical arm
  integer :: iTurbine                 ! The ith turbine
  real :: PosVec(3)                   ! Position vector from towerbase to CoG  
  real :: PosVecTraned(3)             ! Transformed position vector from towerbase to CoG  
  real :: MomVec(3)                   ! Moment vector due to turbinebase loads about (offset and CoG) 
  real :: TestRot(3)
  real :: TestLoads(3)
  real :: TestPosVec(3)
      
! Yang: convert tower-base loads to platform loads with respect to the platform reference frame
      LocalLoads(1:3) = PtfmFrcAQWA(1:3)
      PosVec = 0.0
  ! Position vector from tower-base to CoG     
      PosVec = CoG - PtfmRef_AQWA - OffsetWT(:,iTurbine)       ! From tower-base point to CoG
      PosVec(3) = PosVec(3) - LenTwrBs2Ref                    ! From tower-base to platform reference
      call CrossProd (MomVec,LocalLoads(1:3),PosVec)
      LocalLoads(4:6) = PtfmMomAQWA + MomVec
      
      call getTransMatEuler(TransMat, Rots)

      !AddedPtfmLds = LocalLoads
      AddedPtfmLds(1) = DOT_PRODUCT(LocalLoads(1:3),TransMat(1,:))   ! Surge force
      AddedPtfmLds(2) = DOT_PRODUCT(LocalLoads(1:3),TransMat(2,:))   ! Sway  force
      AddedPtfmLds(3) = DOT_PRODUCT(LocalLoads(1:3),TransMat(3,:))   ! Heave force
      AddedPtfmLds(4) = DOT_PRODUCT(LocalLoads(4:6),TransMat(1,:))   ! Roll  moment
      AddedPtfmLds(5) = DOT_PRODUCT(LocalLoads(4:6),TransMat(2,:))   ! Pitch moment
      AddedPtfmLds(6) = DOT_PRODUCT(LocalLoads(4:6),TransMat(3,:))   ! Yaw   moment
        
  END SUBROUTINE ConvertPtfLds 
! ======================================================================================== 
! ========================================================================================
! SUBROUTINE getTransMat:
! Purpose: get the transform matrix due to local rotations based on small-rotation assumption
! ========================================================================================

SUBROUTINE getTransMat (Theta1,Theta2,Theta3, TransMat)
IMPLICIT NONE
real  :: TransMat(3,3)
real  :: Theta1,Theta2,Theta3,Theta11,Theta22,Theta33,sumSq,SqrtSumSq,ComDenom,Theta12S,Theta13S,Theta23S

Theta11 = Theta1*Theta1
Theta22 = Theta2*Theta2
Theta33 = Theta3*Theta3
sumSq = Theta11 + Theta22 + Theta33
SqrtSumSq = sqrt(sumSq+1.0)
ComDenom = sumSq*SqrtSumSq
Theta12S = Theta1*Theta2*(SqrtSumSq - 1.0)
Theta13S = Theta1*Theta3*(SqrtSumSq - 1.0)
Theta23S = Theta2*Theta3*(SqrtSumSq - 1.0)

if (ComDenom == 0) then
    TransMat(1,:) = (/ 1.0, 0.0, 0.0 /)
    TransMat(2,:) = (/ 0.0, 1.0, 0.0 /)
    TransMat(3,:) = (/ 0.0, 0.0, 1.0 /)

else
    TransMat(1,1) = (Theta11*SqrtSumSq+Theta22+Theta33)/ComDenom
    TransMat(2,2) = (Theta22*SqrtSumSq+Theta11+Theta33)/ComDenom
    TransMat(3,3) = (Theta33*SqrtSumSq+Theta11+Theta22)/ComDenom
    TransMat(1,2) = ( Theta3*sumSq + Theta12S)/ComDenom
    TransMat(2,1) = (-Theta3*sumSq + Theta12S)/ComDenom
    TransMat(1,3) = (-Theta2*sumSq + Theta13S)/ComDenom
    TransMat(3,1) = ( Theta2*sumSq + Theta13S)/ComDenom
    TransMat(2,3) = ( Theta1*sumSq + Theta23S)/ComDenom
    TransMat(3,2) = (-Theta1*sumSq + Theta23S)/ComDenom
endif
END SUBROUTINE getTransMat
! ======================================================================================== 
  
! ========================================================================================
! SUBROUTINE getDateTime
! Purpose: get data and time strings which will be output in the result files
! ========================================================================================
  
  SUBROUTINE getDateTime
  
  USE F2AModules
  
  IMPLICIT NONE
  
   call date_and_time(DATE=Currdate,Time=CurrTime)
   Time_Date = 'at '//CurrTime(1:2)//':'//CurrTime(3:4)//':'//CurrTime(5:6)
   Time_Date = trim(Time_Date)//' on '//Currdate(7:8)//'-'//Currdate(5:6)//'-'//Currdate(1:4)
  
  END SUBROUTINE getDateTime
! ======================================================================================== 
 
! ========================================================================================
! SUBROUTINE getTwrBsLds
! Purpose: get tower base loads through FAST program, FAST will be invoked
! ======================================================================================== 
  SUBROUTINE getTwrBsLds (TIME,STAGE,TmStp,Mot,Vel,CoG,MODE)
  
  USE F2AModules
  USE AQWAinFAST
  !USE FASTProgram 
  !USE TurbConf, ONLY: PtfmRef     ! distance between tower-base and platform reference point
  
  IMPLICIT NONE
  
  real,intent(in) :: Mot(6),Vel(6)   ! Displacement, velcity  of the platform
  real,intent(in)  :: TmStp          ! Time step in AQWA
  real :: TransMat(3,3)              ! Transformation matrix
  real,intent(in)  :: CoG(3)         ! CoG of the platform
  real,intent(in) :: TIME            ! Current simulation time in AQWA               
  integer,intent(in) :: STAGE        ! Simulation stage                
  integer :: iSts,iStps              ! local variables
  integer :: iterm                   ! local variables
  real :: LocMot(6), LocVel(6), LocAcce(6)    ! Local displacement, velocity and acceleration vectors
  integer,intent(in) :: MODE 
  real :: HlfDTAQWA
  real :: PosVec(3)                 ! Position vector from reference point to CoG
  real :: PosVecTraned(3)           ! Translated position vector from CoG to Offset towerbase
  real :: VelVec(3)                 ! Velocity due to rotations of the platform

      PosVec = CoG -  OffsetWT(:,iTurbine) 
      PosVec(3) = PosVec(3) - PtfmRef_AQWA
      HlfDTAQWA =  0.50*TmStp 
      !LocMot = Mot
      !LocVel = Vel
! Correct position vector from (Origin to CoG) TO (Origin to Reference point)

     call getTransMatEuler(TransMat,Mot(4:6)) ! get the transformation matrix for the reference point using Euler angle transformation.
     PosVecTraned(1) = TransMat(1,1) * PosVec(1) + TransMat(1,2) * PosVec(2) + TransMat(1,3) * PosVec(3)
     PosVecTraned(2) = TransMat(2,1) * PosVec(1) + TransMat(2,2) * PosVec(2) + TransMat(2,3) * PosVec(3)
     PosVecTraned(3) = TransMat(3,1) * PosVec(1) + TransMat(3,2) * PosVec(2) + TransMat(3,3) * PosVec(3)
     !PosVecTraned = matmul(TransMat,PosVec)   ! transformed vector from CoG to platform reference point
     LocMot(1:3) = Mot(1:3) - PosVecTraned -  OffsetWT(:,iTurbine)    ! Motion at platform reference point
     LocMot(4:6) = Mot(4:6)   ! Rotation
       
     
     call CrossProd(VelVec,Vel(4:6),PosVecTraned) ! Velocity due to rotations
     LocVel(1:3) = Vel(1:3) - VelVec              ! Velocity at reference point w.r.t inertial frame
     LocVel(4:6) = Vel(4:6)   ! Rotational velocity
         
    
! Detertime status imported into FAST  
      if (TIME == 0 ) then
          !iSts = 0              ! initialize FAST
          if (STAGE == 1) then
              !iStps = 1
              !PrtFASTRslts = .TRUE.
              VelLast1 = LocVel
              LocAcce = 0.0
          else                 ! Time marching
              LocAcce = (LocVel - VelLast1)/TmStp
              VelLast1 = LocVel
              !iStps = RatioStep
              !PrtFASTRslts = .FALSE.
          endif
      else     ! time marching
          if (STAGE == 1) then
             LocAcce = (LocVel - VelLast1)/TmStp
             VelLast1 = LocVel
          else
             LocAcce = (LocVel - VelLast2)/TmStp
             VelLast2 = LocVel
          endif
         
      endif
     
! Calculate the restoring forces used in ElastoDyn to represent the platform effects on tower
     !if (PtfmRestoreFlag == 0)  then
     !    PtfmRestLoads = 0.0
     !else
     !    PtfmRestLoads(3:5) = -matmul(PtfmStffMat(3:5,3:5),LocMot(3:5))
     !    PtfmRestLoads(1:6) =  PtfmRestLoads(1:6) + OffsetLoads
     !endif
                 
! Call FAST to march 1/2 TIMESTEP for STAGE 1 and STAGE 2, respectively
      call  FAST (TIME,NumWTs,HlfDTAQWA,STAGE,PriFile(iTurbine),LocMot,LocVel,LocAcce,MODE)
! Complete invoking FAST program.

  END SUBROUTINE getTwrBsLds
! ======================================================================================== 
  
! ========================================================================================
! SUBROUTINE: getTransMat2. transformation based on the Euler-angle rule
! ========================================================================================
SUBROUTINE   getTransMatEuler(TransMat, Rots)

implicit none

  real :: TransMat (3,3)       ! Transformation matrix
  real :: Rots (3)             ! Rotations
  real :: cx,cy,cz             ! Cosines
  real :: sx,sy,sz             ! Sines


  cx = cos(Rots(1));
  sx = sin(Rots(1));
  cy = cos(Rots(2));
  sy = sin(Rots(2));
  cz = cos(Rots(3));
  sz = sin(Rots(3));
  
  TransMat(1,:) = (/ cz*cy, -sz*cx+cz*sy*sx, sz*sx+cz*sy*cx /)
  TransMat(2,:) = (/sz*cy,  cz*cx+sz*sy*sx, -cz*sx+sz*sy*cx /)
  TransMat(3,:) = (/ -sy  ,   cy*sx ,     cy*cx       /)
  
  END SUBROUTINE getTransMatEuler
! ========================================================================================

! ========================================================================================
! SUBROUTINE: CrossProd. cross product
! ========================================================================================
  SUBROUTINE CrossProd(VecResult, Vector1, Vector2)
   ! VecResult = Vector1 X Vector2 (resulting in a vector)
IMPLICIT NONE

   ! Passed variables:

REAL, INTENT(OUT)         :: VecResult (3)   ! = Vector1 X Vector2 (resulting in a vector)
REAL, INTENT(IN )         :: Vector1   (3)
REAL, INTENT(IN )         :: Vector2   (3)

VecResult(1) = Vector1(2)*Vector2(3) - Vector1(3)*Vector2(2)
VecResult(2) = Vector1(3)*Vector2(1) - Vector1(1)*Vector2(3)
VecResult(3) = Vector1(1)*Vector2(2) - Vector1(2)*Vector2(1)

RETURN
  END SUBROUTINE CrossProd
! ========================================================================================
  
! ========================================================================================
! SUBROUTINE: getOpenF2AInput
! Purpose: Read input defnitions of the IFES model
! ========================================================================================
SUBROUTINE getOpenF2AInput 
USE F2AModules
IMPLICIT NONE

character(len=2) :: TempChar
integer :: iWrite
integer :: iread,i,j

    open (UnPIn,file='InputforOpenF2A.txt')
     read (UnPIn,*) ! This is an input file of OpenF2A (OpenFAST-to-AQWA) for dynamic analysis of floating offshore wind turbines (FOWTs)
     read (UnPIn,*) ! This file is specified for the OC4 DeepCWind FOWT case.! and several(<10) tidal turbines. This file is specified for the IFES model that contains one wind turbine and two tidal turbines supported by the OC5 DeepCWind platform.
     read (UnPIn,*) ! Do not remove anyline below. Three lines of comments in total.
     read (UnPIn,*) ! --------------- FAST Configuration ------------------
     read (UnPIn,*) NumWTs		    !- NumWTs			! Number of wind turbines incorprated into the modelling. The Prifile, IdStr and Offsets will be read by the code in a loop.
     allocate (Prifile(NumWTs))
     allocate (IdStr(NumWTs))
     allocate (OffsetWT(3,NumWTs))
     do iread = 1,NumWTs
        read (UnPIn,*) Prifile(iread)		                ! Primary input file of the (ith) wind turbine for OpenFAST     
     enddo
     read (UnPIn,*) (IdStr(iread),iread=1,NumWTs)	        ! Index of structure modelled in AQWA that connects to the ith wind turbine
     do iread = 1,NumWTs
        read (UnPIn,*) OffsetWT(1,iread),OffsetWT(2,iread),OffsetWT(3,iread)	! Offset of the ith tind turbine's reference coordinate system 
     enddo ! end of reading the FAST wind turbine configuration
     !read (UnPIn,*) PtfmRestoreFlag 	                ! Primary input file of the (ith) wind turbine for OpenFAST
     !if (PtfmRestoreFlag/=0)  then
     !    read (UnPIn,*) PtfmVol0        
     !    read (UnPIn,*) PtfmCOBxt         
     !    read (UnPIn,*) PtfmCOByt         
     !    do iread = 1,6
     !       read (UnPIn,*) PtfmStffMat(iread,1:6)
     !    enddo
     ! 
     !    do iread = 1,6
     !       read (UnPIn,*) PtfmAddedMassMat(iread,1:6)
     !    enddo          
     !endif          
    close(UnPIn) ! END of reading the inputs of OpenF2A
    
    write (TempChar,'(I2)') NumWTs
    if (NumWTs == 1) then
       write (*,*) ' There is '//trim(adjustl(TempChar))//' wind turbine considered.'
       write (*,*) ' Using FAST input file: ' ,trim(Prifile(1))
    else
       write (*,*) ' There are '//trim(adjustl(TempChar))//' wind turbines considered.'
       do iWrite=1,NumWTs
          write (*,*) ' Using FAST input file: ' ,trim(Prifile(iWrite))
       enddo
    endif
END SUBROUTINE getOpenF2AInput
! ========================================================================================
! ========================================================================================
! SUBROUTINE: correctStiffMass
! Purpose: correct Stiffness and Mass matrices of platform provided by the users
! ========================================================================================
SUBROUTINE correctStiffMass 
USE F2AModules
IMPLICIT NONE

real :: massTranMat(6,6)
real :: CorrectMass(6,6)
real :: TempMass(6,6)

   if (PtfmRestoreFlag==2) then  ! referred to CM, we need to correct it considering the restoring due to mass center (only K44 K55 is corrected)
       PtfmStffMat(4,4) = PtfmStffMat(4,4) + gAcceScale * RhoSea*PtfmVol0*(CoGPtfm(3))
       PtfmStffMat(5,5) = PtfmStffMat(5,5) + gAcceScale * RhoSea*PtfmVol0*(CoGPtfm(3))
       TempMass = PtfmAddedMassMat            
       massTranMat (1,:) = (/ 1.0, 0.0, 0.0, 0.0,             CoGPtfm(3),     -CoGPtfm(2) /)
       massTranMat (2,:) = (/ 0.0, 1.0, 0.0, -CoGPtfm(3),    0.0,             CoGPtfm(1) /)
       massTranMat (3,:) = (/ 0.0, 0.0, 1.0, CoGPtfm(2),   -CoGPtfm(1),     0.0 /)
       massTranMat (4,:) = (/ 0.0, 0.0, 0.0, 1.0,             0.0,              0.0 /)
       massTranMat (5,:) = (/ 0.0, 0.0, 0.0, 0.0,             1.0,              0.0 /)
       massTranMat (6,:) = (/ 0.0, 0.0, 0.0, 0.0,             0.0,              1.0 /)
       CorrectMass = matmul(transpose(massTranMat),TempMass)
       PtfmAddedMassMat = matmul(CorrectMass,massTranMat)
       OffsetLoads = 0.0
       OffsetLoads(3) =  gAcceScale * RhoSea*PtfmVol0
       OffsetLoads(4) =  OffsetLoads(3) * PtfmCOByt
       OffsetLoads(5) = -OffsetLoads(3) * PtfmCOBxt
   endif

END SUBROUTINE correctStiffMass
! ========================================================================================
! SUBROUTINE WrtNoticeOpenF2A:
! Purpose: Write a notice to tell USErs the version info of F2A
! ========================================================================================
SUBROUTINE WrtNoticeOpenF2A 

USE F2AModules

IMPLICIT NONE


 
! Write notice to the USEr:
    write (*,*) '---------------------------------------------------------------------------'
    write (*,*) '-----------------------       OpenF2A        -----------------------------'
    write (*,*) '------------------   (v4.00.00-yy, 24-June-2025)    ----------------------'
    write (*,*) '---------------------------------------------------------------------------',&
                ' OpenF2A is originally developed by Professor Yang Yang in Ningbo University',&
				' by incorporating OpenFAST with AQWA for conducting fully-coupled simulations',&
				' of floating offshore wind turbines. The source code is released to the public',&
				' for free, which can be found on Github repositoriy of yang7857584/OpenF2A',&
                '---------------------------------------------------------------------------'
    write (*,*) 
    
END SUBROUTINE WrtNoticeOpenF2A
! ========================================================================================


END MODULE F2ASubs
    
