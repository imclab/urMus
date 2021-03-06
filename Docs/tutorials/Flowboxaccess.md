Integrating Flowboxes from the urMus mapping interface with lua
=======

* * * * *

In this tutorial we will show how we can send data into an existing urMus patch that we built in the default interface.
The main flowbox to use to send data to is called Push. So if we want to give a script or interface access to our patch,
We should use Push flowboxes as the points of interface.

For this first example build a patch in the default urMus interface that looks like this:

<img width=320 src="Images/PushExampleDac.png">

Now we write a program that checks if push blocks have been placed and if yes sends random numbers into them.

Simple example how to access Push instances from within lua.

Each flowbox has a global prototype/factory. We can access it via `_G["FB..."]` where ... is the Flowbox name with correct caps.

Technical Note (skip at will): The default urMus interface will store instances inside the flowbox
This is not required behavior but is offered by the interface for convenience here.

So we check if instances exist. If the first instance exists we can Push data into it. If a second instance exists we can Push more data into that.

	function PushRandom(self)
		local pushflowbox = _G["FBPush"]
	
		if pushflowbox.instances and pushflowbox.instances[1]  then
			pushflowbox.instances[1]:Push(math.random())
	
			if pushflowbox.instances[2] then
				pushflowbox.instances[2]:Push(math.random())
			end
		end
	end

	-- Create an invisible region that takes touch inputs.
	r = Region()
	r:SetWidth(ScreenWidth())
	r:SetHeight(ScreenHeight())
	r:Handle("OnTouchDown", PushRandom)
	r:EnableInput(true)
	r.t = r:Texture(255,0,0,255)
	r:Show()

Let's build a continuous example. Here we use the touch coordinates to send data to the urMus patch.

	FreeAllRegions()
	
	function PushRandom(self,elapsed)
		
		if not pressed then return end
		
		-- InputPosition returns the coordinates of the last touch event
		local x,y = InputPosition()
		local pushflowbox = _G["FBPush"]
		
		if pushflowbox.instances and pushflowbox.instances[1]  then
			pushflowbox.instances[1]:Push(x/ScreenWidth())
			if pushflowbox.instances[2] then
				pushflowbox.instances[2]:Push(y/ScreenHeight())
			end
		end
	end
	function Pressed(self)
		pressed = true
	end
	
	function Released(self)
		released = false
	end
	
	r = Region()
	r:SetWidth(ScreenWidth())
	r:SetHeight(ScreenHeight())
	r:Handle("OnTouchDown", Pressed)
	r:Handle("OnTouchUp", Released)
	r:Handle("OnUpdate", PushRandom)
	r:EnableInput(true)

Now let's learn how we can get data from an urMus patch.
The `Vis` flowbox will update a patch whenever the screen is redrawn.
We can get that piece of information from the vis block by calling its
`Get()` function, which always contains the latest data.
Usually that information is then used to render some visual representation.

Let's go to the urMus default interface an build a new patch:

<img width=320 src="Images/PushExampleVis.png">

First we grab a copy of the global version of the Vis flowbox.

	local vis = _G["FBVis"]
	
	function Draw(self)
		local visout = vis:Get()
	
		if visout > 0 then
			self.t:SetBrushColor(255,0,0,255)
		else
			self.t:SetBrushColor(0,255,0,255)
		end
		self.t:Clear(255,255,255,255)
		local radius = visout*ScreenWidth()/2
		self.t:Ellipse(ScreenWidth()/2,ScreenHeight()/2,radius, radius)
		PushRandom(self)
	end    
	
	-- We prepare a texture to draw into
	
	r.t = r:Texture(255,255,255,255)
	r.t:SetTexCoord(0,320.0/512.0,480.0/512.0,0.0)
	r.t:SetBrushSize(8)
	r:Show()
	
	r:Handle("OnUpdate",Draw)

Now we have seen how to both send data from lua to a patch via Push flowboxes and how to receive data from a patch in lua via Vis flowboxes. One can build complete patches using the urMus lua API but this is for another tutorial.

Writing Flowbox patches in lua
=======

* * * * *

Now we are going to write complete dataflow patches in lua. The most important missing piece to do so is linking. In order to allow data-flow between two flowboxes they need to be linked up. In urMus links are directional. They can either go upstream, from sink towards sources, or downstream, from sources to sink. In urMus we call downstream links `Pushes`. Upstream links are called `Pulls`. These can either be set or removed. In order to establish a link one has to pick an inlet of one flowbox and connect it to an outlet of another flowbox. An outlet can push into an inlet and an inlet can pull from an outlet. If this is too complicated, let us start writing a first very simple patch:

	local dac = FBDac
	local accel = FBAccel
	local sinosc = FlowBox(FBSinOsc) -- Grab a new instance of a sin oscillator

	dac.In:SetPull(sinosc.Out) -- Sinks like to pull data.
	accel.X:SetPush(sinosc.Freq) -- Sources like to push data.
	
We make local copies of the Dac sink and the Accel source for convenience. There is only one Dac on the mobile device so we do not need to create an instance of it. Same holds for Accel as only one accelerometer sensor is present on the device. In general hardware sources and sink do not need to be instanced. However most other things do need to be instanced as we can have many of them! To create a new instance of a flowbox, we use the global FlowBox() function. We provide the prototype of the flowbox we want instanced as argument. In our case this is FBSinOsc. Now we have all the pieces. An Accel source, the Dac sink and a new instance of a SinOsc. Next step is to link them all up. The precise detail how to choose link directions can be complicated, but in this case it is easy. Hardware tends to provide or request data. Sinks request data, and sources provide data. Hence the first wants to pull, and the later wants to push.

In order to create the connection we use the SetPull() and SetPush() methods of the inlets and outlets we want to connect. For example we want the In inlet of the Dac to receive data from the SinOsc.Out outlet. We call dac.In:SetPull(SinOsc.Out) to do so. SetPull() calls are always associated with inlets. Conversely the accel.X provides data so we call accel.X:SetPush(sinosc.Freq) to feed the x-axis accelerometer data into the frequency inlet of the sinosc.

Now we can wiggle the mobile device sideways and make some noise. To clear out existing patches we can call:

	FreeAllFlowboxes()
	
This gets rid of the patch and the noise.

There are a few special flowboxes. FBSample is an important one. It allows to play back sample files. Hence we need a way to specify which samples to use:

	FreeAllFlowboxes()
	local dac = FBDac
	local accel = FBAccel
	local sample = FlowBox(FBSample) 

	sample:AddFile("White-Mono.wav") -- Specify an audio file 

	dac.In:SetPull(sample.Out)
	accel.X:SetPush(sample.Rate) 

We use the AddFile method to specify the wav file we want to use. We can upload and use other wav files. Currently urMus expects the file to be 48000Hz mono. The FBSample flowbox can in fact take multiple filenames and select which one in the list of specified names to use for playback. In this example we control the playback rate hence can speed up, slow down and reverse the playback speed.

	FreeAllFlowboxes()
	local dac = FBDac
	local accel = FBAccel
	local sample = FlowBox(FBSample) 

	sample:AddFile("White-Mono.wav")
	sample:AddFile("Red-Mono.wav") -- Specify a second audio file

	dac.In:SetPull(sample.Out)
	accel.X:SetPush(sample.Rate) 
	accel.Y:SetPush(sample.Sample)
	
Here we added a second sample file and selection for the sample file via the Sample inlet of the FBSample flowbox.

