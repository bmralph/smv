! VVVVV placeholder modules - will not be moved to FDS VVVVV

! ------------ module PRECISION_PARAMETERS

MODULE PRECISION_PARAMETERS
 
! Set important parameters having to do with variable precision and array allocations
 
IMPLICIT NONE
 
! Precision of "Four Byte" and "Eight Byte" reals

INTEGER, PARAMETER :: FB = SELECTED_REAL_KIND(6)
INTEGER, PARAMETER :: EB = SELECTED_REAL_KIND(12)
END MODULE PRECISION_PARAMETERS

MODULE MEMORY_FUNCTIONS
USE COMP_FUNCTIONS, ONLY: SHUTDOWN

CONTAINS
SUBROUTINE ChkMemErr(CodeSect,VarName,IZERO)
 
! Memory checking routine
 
CHARACTER(*), INTENT(IN) :: CodeSect, VarName
INTEGER IZERO
CHARACTER(100) MESSAGE
 
IF (IZERO==0) RETURN
 
WRITE(MESSAGE,'(4A)') 'ERROR: Memory allocation failed for ', TRIM(VarName),' in the routine ',TRIM(CodeSect)
CALL SHUTDOWN(MESSAGE)

END SUBROUTINE ChkMemErr
END MODULE MEMORY_FUNCTIONS

! ------------ module COMP_FUNCTIONS

MODULE COMP_FUNCTIONS

CONTAINS
SUBROUTINE SHUTDOWN(MESSAGE)  
CHARACTER(*), INTENT(IN) :: MESSAGE

WRITE(6,'(/A)') TRIM(MESSAGE)

STOP

END SUBROUTINE SHUTDOWN

SUBROUTINE CHECKREAD(NAME,LU,IOS)

! Look for the namelist variable NAME and then stop at that line.

INTEGER :: II
INTEGER, INTENT(OUT) :: IOS
INTEGER, INTENT(IN) :: LU
CHARACTER(4), INTENT(IN) :: NAME
CHARACTER(80) TEXT
IOS = 1

READLOOP: DO
   READ(LU,'(A)',END=10) TEXT
   TLOOP: DO II=1,72
      IF (TEXT(II:II)/='&' .AND. TEXT(II:II)/=' ') EXIT TLOOP
      IF (TEXT(II:II)=='&') THEN
         IF (TEXT(II+1:II+4)==NAME) THEN
            BACKSPACE(LU)
            IOS = 0
            EXIT READLOOP
         ELSE
            CYCLE READLOOP
         ENDIF
      ENDIF
   ENDDO TLOOP
ENDDO READLOOP
 
10 RETURN
END SUBROUTINE CHECKREAD
END MODULE COMP_FUNCTIONS

! ^^^^ placeholder routines and modules ^^^^^^^

! ------------ module TYPES

MODULE TYPES
USE PRECISION_PARAMETERS

TYPE GEOMETRY_TYPE ! this TYPE definition will be moved to FDS
   CHARACTER(30) :: ID='geom'
   CHARACTER(30) :: SURF_ID='null'
   INTEGER :: N_VERTS, N_FACES
   INTEGER, ALLOCATABLE, DIMENSION(:) :: FACES
   REAL(EB), ALLOCATABLE, DIMENSION(:) :: VERTS
END TYPE GEOMETRY_TYPE
INTEGER :: N_GEOM=0
TYPE(GEOMETRY_TYPE), ALLOCATABLE, TARGET, DIMENSION(:) :: GEOMETRY
END MODULE TYPES

! ------------ module GLOBAL_CONSTANTS

MODULE GLOBAL_CONSTANTS
USE PRECISION_PARAMETERS
IMPLICIT NONE

INTEGER :: LU_INPUT=5, LU_GEOM(1)=15, LU_SMV=4
CHARACTER(40) :: CHID
CHARACTER(250)                             :: FN_INPUT='null'
CHARACTER(80) :: FN_SMV,FN_GEOM(1)
END MODULE GLOBAL_CONSTANTS

MODULE READ_INPUT

USE PRECISION_PARAMETERS
USE GLOBAL_CONSTANTS
USE COMP_FUNCTIONS, ONLY: CHECKREAD,SHUTDOWN

PRIVATE
PUBLIC :: READ_HEAD

CONTAINS
SUBROUTINE READ_HEAD
INTEGER :: NAMELENGTH
NAMELIST /HEAD/ CHID

CHID    = 'null'

REWIND(LU_INPUT)
HEAD_LOOP: DO
   CALL CHECKREAD('HEAD',LU_INPUT,IOS)
   IF (IOS==1) EXIT HEAD_LOOP
   READ(LU_INPUT,HEAD,END=13,ERR=14,IOSTAT=IOS)
   14 IF (IOS>0) CALL SHUTDOWN('ERROR: Problem with HEAD line')
ENDDO HEAD_LOOP
13 REWIND(LU_INPUT)

CLOOP: DO I=1,39
   IF (CHID(I:I)=='.') CALL SHUTDOWN('ERROR: No periods allowed in CHID')
   IF (CHID(I:I)==' ') EXIT CLOOP
ENDDO CLOOP

IF (TRIM(CHID)=='null') THEN
   NAMELENGTH = LEN_TRIM(FN_INPUT)
   ROOTNAME: DO I=NAMELENGTH,2,-1
      IF (FN_INPUT(I:I)=='.') THEN
         WRITE(CHID,'(A)') FN_INPUT(1:I-1)
         EXIT ROOTNAME
      ENDIF
   END DO ROOTNAME
ENDIF

FN_SMV=TRIM(CHID)//'.smv'
FN_GEOM(1)=TRIM(CHID)//'.ge'

END SUBROUTINE READ_HEAD
END MODULE READ_INPUT


