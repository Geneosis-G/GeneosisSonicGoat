class SuperSonicGoat extends GGMutator
	config(Geneosis);

var array<GGGoat> superGoats;
var config bool isSuperSonicUnlocked;

/**
 * if the mutator should be selectable in the Custom Game Menu.
 */
static function bool IsUnlocked( optional out array<AchievementDetails> out_CachedAchievements )
{
	//Function not called on custom mutators for now so this is not working
	return default.isSuperSonicUnlocked;
}

/**
 * Unlock the mutator
 */
static function UnlockSuperSonicGoat()
{
	if(!default.isSuperSonicUnlocked)
	{
		PostJuice( "Unlocked Super Sonic Goat" );
		default.isSuperSonicUnlocked=true;
		static.StaticSaveConfig();
	}
}

function static PostJuice( string text )
{
	local GGGameInfo GGGI;
	local GGPlayerControllerGame GGPCG;
	local GGHUD localHUD;

	GGGI = GGGameInfo( class'WorldInfo'.static.GetWorldInfo().Game );
	GGPCG = GGPlayerControllerGame( GGGI.GetALocalPlayerController() );

	localHUD = GGHUD( GGPCG.myHUD );

	if( localHUD != none && localHUD.mHUDMovie != none )
	{
		localHUD.mHUDMovie.AddJuice( text );
	}
}

/**
 * See super.
 */
function ModifyPlayer(Pawn Other)
{
	local GGGoat goat;

	goat = GGGoat( other );

	if( goat != none )
	{
		if( IsValidForPlayer( goat ) )
		{
			if(!default.isSuperSonicUnlocked)
			{
				DisplayLockMessage();
			}
			else
			{
				superGoats.AddItem(goat);
				ClearTimer(NameOf(InitSuperSonics));
				SetTimer(1.f, false, NameOf(InitSuperSonics));
			}
		}
	}
	
	super.ModifyPlayer( other );
}

function InitSuperSonics()
{
	local SonicGoat sonic;
	local GGGoat goat;
	
	//Find Sonic Goat mutator
	foreach AllActors(class'SonicGoat', sonic)
	{
		if(sonic != none)
		{
			break;
		}
	}
	
	if(sonic == none)
	{
		DisplayUnavailableMessage();
		return;
	}
	
	//Activate super sonic mode
	foreach superGoats(goat)
	{
		sonic.InitSuperSonics(goat);
	}
}

function DisplayUnavailableMessage()
{
	WorldInfo.Game.Broadcast(self, "Super Sonic Goat only works if combined with Sonic Goat.");
	SetTimer(3.f, false, NameOf(DisplayUnavailableMessage));
}

function DisplayLockMessage()
{
	ClearTimer(NameOf(DisplayLockMessage));
	WorldInfo.Game.Broadcast(self, "Super Sonic Goat Locked :( Collect 142 Rings to unlock it.");
	SetTimer(3.f, false, NameOf(DisplayLockMessage));
}

DefaultProperties
{
	
}