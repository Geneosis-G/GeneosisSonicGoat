class SonicRings extends GGMutator;

var array<GGGoat> ringsGoats;

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
			ringsGoats.AddItem(goat);
			ClearTimer(NameOf(InitRings));
			SetTimer(1.f, false, NameOf(InitRings));
		}
	}

	super.ModifyPlayer( other );
}

function InitRings()
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

	//Spawn rings and allow goats to collect them
	foreach ringsGoats(goat)
	{
		sonic.InitRings(goat);
	}
}

function DisplayUnavailableMessage()
{
	WorldInfo.Game.Broadcast(self, "Sonic Rings only works if combined with Sonic Goat.");
	SetTimer(3.f, false, NameOf(DisplayUnavailableMessage));
}

DefaultProperties
{

}