@echo off
setlocal enabledelayedexpansion

:: ============================================================================
:: Art Fight Manager - v1.0.5
:: - FIXED the crash when using space-separated multi-selection.
:: - Implemented a robust check for range vs. space input.
:: ============================================================================

:menu
cls
echo.
echo   Art Fight Manager
echo ============================
echo   [1] Add a NEW user (and their characters)
echo   [2] Add characters to an EXISTING user
echo   [3] Move reference image(s) to a character folder
echo   [4] Exit
echo.
set /p "choice=Select an option: "

if "%choice%"=="1" goto new_user_setup
if "%choice%"=="2" goto existing_user_select
if "%choice%"=="3" goto move_image
if "%choice%"=="4" exit /b
goto menu

:: ============================================================================
:new_user_setup
:: (This section is unchanged)
cls
echo. & echo --- [1] New User Setup --- & echo. & set /p "target=Enter new target USERNAME: "
if not defined target goto menu
echo. & echo --- Creating assets for user: !target! ---
mkdir "!target!" 2>nul
(echo [InternetShortcut] & echo URL=https://artfight.net/~!target!) > "!target!\!target!_Profile.url"
echo   - Created profile shortcut.
echo. & echo --- Populating global terms for !target! --- & echo    (Press Enter on a blank line when finished with a section)
(echo --- Do's and Don'ts for !target! --- & echo. & echo ## DO: ##) > "!target!\terms.txt"
:do_loop
set "do_item=" & set /p "do_item=  - DO: "
if not defined do_item goto add_donts
echo   !do_item! >> "!target!\terms.txt" & goto do_loop
:add_donts
(echo. & echo ## DON'T: ##) >> "!target!\terms.txt"
:dont_loop
set "dont_item=" & set /p "dont_item=  - DON'T: "
if not defined dont_item goto terms_done
echo   !dont_item! >> "!target!\terms.txt" & goto dont_loop
:terms_done
echo. & echo   - Created and populated terms.txt & start "" notepad "!target!\terms.txt"
goto character_loop

:: ============================================================================
:existing_user_select
:: (This section is unchanged)
cls
echo. & echo --- [2] Select Existing User --- & echo.
set "count=0"
for /f "delims=" %%d in ('dir /b /ad *') do (set /a count+=1 & echo   [!count!] %%d & set "user_list[!count!]=%%d")
if %count%==0 (echo   No user folders found. & echo. & pause & goto menu)
echo. & set /p "user_choice=Choose a user number: "
if not defined user_choice goto menu
set "target=!user_list[%user_choice%]!"
if not defined target (echo   Invalid selection. & pause & goto menu)
echo. & echo --- Selected user: !target! --- & pause
goto character_loop

:: ============================================================================
:character_loop
:: (This section is unchanged)
:inner_char_loop
cls
echo. & echo --- Adding Characters for [!target!] --- & echo    (Press Enter on a blank name to finish) & echo.
set "char_name=" & set "char_id="
set /p "char_name=Enter CHARACTER name: "
if not defined char_name goto menu
set /p "char_id=Enter CHARACTER ID: "
if not defined char_id (echo Character ID cannot be empty. & pause & goto inner_char_loop)
set "char_folder=!target!\!char_name!" & mkdir "!char_folder!" 2>nul
echo. & echo --- Creating assets for character: !char_name! ---
(echo Character: !char_name! & echo User: !target! & echo ID: !char_id! & echo. & echo --- Description --- & echo.) > "!char_folder!\description.txt"
echo   - Created description.txt
(echo @echo off & echo echo !char_id! ^| clip & echo echo   Character ID [!char_id!] copied to clipboard! & echo   timeout /t 2 /nobreak ^>nul) > "!char_folder!\Copy_ID.bat"
echo   - Created clickable ID copier: Copy_ID.bat
start "" notepad "!char_folder!\description.txt"
echo. & echo   Character [!char_name!] added successfully. & pause
goto inner_char_loop

:: ============================================================================
:: THIS IS THE FIXED AND UPGRADED SECTION
:: ============================================================================
:move_image
cls
echo. & echo --- [3] Move Reference Image(s) --- & echo.
echo --- Step 1: Select images to move ---
set "img_count=0"
for /f "delims=" %%f in ('dir /b *.jpg *.jpeg *.png *.gif *.webp 2^>nul') do (
    set /a img_count+=1
    echo   [!img_count!] %%f
    set "img_list[!img_count!]=%%f"
)
if %img_count%==0 (echo   No image files found. & echo. & pause & goto menu)

echo. & echo Enter numbers to move (e.g., "1 3 4" or "2-5"):
set /p "img_choices=Your selections: "
if not defined img_choices goto move_image

:: Destination selection (User and Character)
cls
echo. & echo --- Step 2: Select a destination user ---
set "user_count=0"
for /f "delims=" %%d in ('dir /b /ad *') do (set /a user_count+=1 & echo   [!user_count!] %%d & set "user_list[!user_count!]=%%d")
if %user_count%==0 (echo   No user folders found. & echo. & pause & goto menu)
echo. & set /p "user_choice=Choose a user folder: "
set "selected_user=!user_list[%user_choice%]!"
if not defined selected_user (echo   Invalid selection. & pause & goto move_image)

cls
echo. & echo --- Step 3: Select a destination character ---
set "char_count=0"
for /f "delims=" %%d in ('dir /b /ad "!selected_user!\"') do (set /a char_count+=1 & echo   [!char_count!] %%d & set "char_list[!char_count!]=%%d")
if %char_count%==0 (echo   No character folders found. & echo. & pause & goto menu)
echo. & set /p "char_choice=Choose a character folder: "
set "selected_char=!char_list[%char_choice%]!"
if not defined selected_char (echo   Invalid selection. & pause & goto move_image)

:: --- Step 4: Perform the moves with robust parsing ---
set "destination_path=!selected_user!\!selected_char!"
echo. & echo --- Moving files to "!destination_path!" ---

:: This is the robust check. It replaces the hyphen with nothing and sees if the string changes.
if "!img_choices!" NEQ "!img_choices:-=!" (
    :: It's a RANGE like "2-5" because removing the "-" changed the string.
    for /f "tokens=1,2 delims=-" %%a in ("!img_choices!") do (
        for /L %%i in (%%a, 1, %%b) do (
            if defined img_list[%%i] (
                echo   - Moving "!img_list[%%i]!"
                move "!img_list[%%i]!" "!destination_path!\" >nul
            ) else (
                echo   - Skipping invalid number %%i in range.
            )
        )
    )
) else (
    :: It's SPACE-SEPARATED numbers like "1 3 4"
    for %%i in (%img_choices%) do (
        if defined img_list[%%i] (
            echo   - Moving "!img_list[%%i]!"
            move "!img_list[%%i]!" "!destination_path!\" >nul
        ) else (
            echo   - Skipping invalid selection '%%i'.
        )
    )
)

echo. & echo   Move operation complete!
echo. & pause
goto menu