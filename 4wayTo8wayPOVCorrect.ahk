;------ Configuration -------
TargetGames := ["Doom`, the Roguelike", "Tales of Maj'Eyal: Age of Ascendancy", "Cogmind*"]
InputKeys := {"Up": "w", "Down": "s", "Left": "a", "Right": "d"}
OutputKeys := {"North": "w", "South": "s", "West": "a", "East": "d", "NW": "Home", "SW": "End", "NE": "PgUp", "SE": "PgDn"}
BufferDelay := 67
KeyReleaseSendsEarly := true
;----------------------------

SetTitleMatchMode, Regex


SentKeys := 0
WaitingForKeys := false
LastKey := ""
BufferDelay := -1 * BufferDelay

SendMode, Input

for index, game in TargetGames
{
	Hotkey, IfWinActive, %game%
	for inkey, val in InputKeys
	{
		Hotkey, *$%val%, HotkeySetupDown
		Hotkey, *$%val% UP, HotkeySetupUp
	}
}

HotkeySetupDown:
StringTrimLeft, hotkeyKey, A_ThisHotkey, 1
HandleKeys(hotkeyKey, true)
return

HotkeySetupUp:
StringTrimLeft, hotkeyKeyUP, A_ThisHotkey, 1
StringSplit, hotkeyKeyParts, hotkeyKeyUP, " "
HandleKeys(hotkeyKeyParts1, false)
return

KeyCheck()
{
	global SentKeys, InputKeys, OutputKeys
	Critical
	

	POVUp := GetKeyState(InputKeys["Up"], "P")
	POVLeft := GetKeyState(InputKeys["Left"], "P") 
	POVDown := GetKeyState(InputKeys["Down"], "P") 
	POVRight := GetKeyState(InputKeys["Right"], "P")

	KeyList := {"North": 0, "South": 0, "West": 0, "East": 0, "NW": 0, "SW": 0, "NE": 0, "SE": 0}


	if (POVUp and POVLeft)
	{
		KeyList["NW"] := 1
		SentKeys := 2
	}
	else if (POVDown and POVLeft)
	{
		KeyList["SW"] := 1
		SentKeys := 2
	}
	else if (POVUp and POVRight)
	{
		KeyList["NE"] := 1
		SentKeys := 2
	}
	else if (POVDown and POVRight)
	{
		KeyList["SE"] := 1
		SentKeys := 2
	}
	else if (POVUp)
	{
		KeyList["North"] := 1
		SentKeys := 1
	}
	else if (POVDown)
	{
		KeyList["South"] := 1
		SentKeys := 1
	}
	else if (POVLeft)
	{
		KeyList["West"] := 1
		SentKeys := 1
	}
	else if (POVRight)
	{
		KeyList["East"] := 1
		SentKeys := 1
	}
	else
	{
		SentKeys := 0
	}

	SetKeyDelay -1 ; Avoid delays between keystrokes.
	for Dir, KeyState in KeyList ; Update all keys
	{
		Key := OutputKeys[Dir]
		if (GetKeyState(Key) != KeyState) ; Check if the keyboard key state matches the POV direction.
		{
			if (KeyState) ; Check if we need to press this key down...
			;~ {
				;~ Send {Space}
				;~ Send {Space}
				;~ Send, {%Key% down}
				;~ Send, {%Key% up}
			;~ }
				Send, {Blind}{%Key% down}
			else ; ...or up.
				;~ Send, {Up}
				Send, {Blind}{%Key% up}
		}
	}
	SetKeyDelay -1  ; Avoid delays between keystrokes.
}

ReleaseBuffer:
if (WaitingForKeys)
{
	KeyCheck()
	WaitingForKeys := false
}
return

HandleKeys(Key, Pressed)
{
	global LastKey, WaitingForKeys, SentKeys, InputKeys, OutputKeys, BufferDelay, KeyReleaseSendsEarly
	;SetTimer ReleaseBuffer, Off ;Explicitly turn off timer to mitigate possible race conditions

	if(WaitingForKeys or SentKeys)
	{
		if (Pressed)
		{
			WaitingForKeys := false
			KeyCheck()
		}
		else if (SentKeys > 0) ;Released with SentKeys
		{
			if (SentKeys = 1)
			{
				WaitingForKeys := false
				KeyCheck()
			}
			else
			{
				WaitingForKeys := true
				SetTimer ReleaseBuffer, % BufferDelay / 2
			}
		}
		else if (KeyReleaseSendsEarly and LastKey = Key) ;Released with only WaitingForKeys
		{
			WaitingForKeys := false
			Sleep, % -1 * BufferDelay / 2
			if (SentKeys > 0) ;- Post-sleep, so double-check preconditions to avoid race condition
				return
			
			KeyToSend := ""
			if (Key = InputKeys["Up"])
				KeyToSend := OutputKeys["North"]
			else if (Key = InputKeys["Left"])
				KeyToSend := OutputKeys["West"]
			else if (Key = InputKeys["Down"])
				KeyToSend := OutputKeys["South"]
			else if (Key = InputKeys["Right"])
				KeyToSend := OutputKeys["East"]
			if (KeyToSend != "")
			{			
				for OutKey, KeyState in OutputKeys
				{
					Send, {Blind}{%OutKey% up} ;- Precaution in case KeyCheck isn't called sufficiently and 

something gets locked up
				}
				Send, {Blind}%KeyToSend%
			}	
		}
	}
	else ;Neither WaitingForKeys nor SentKeys
	{
		if (Pressed)
		{
			WaitingForKeys := true
			LastKey := Key
			SetTimer ReleaseBuffer, %BufferDelay%
		}
	}
}
