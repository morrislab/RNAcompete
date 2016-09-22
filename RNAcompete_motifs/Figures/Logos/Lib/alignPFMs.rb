#!/usr/bin/ruby
require "DNATOOLBOX.rb"
require "fileutils";
inDP=ARGV[0];
inDP+="/" if inDP[-1,1]!="/"
outDP=ARGV[1];
outDP+="/" if outDP[-1,1]!="/"
ynDirs = [];
FileUtils.mkdir_p(outDP);
Dir.open(inDP).each{|curEntry|
	curPath = inDP+curEntry;
	if curEntry=="." || curEntry==".."
		next;
	elsif File.directory?(curPath)
		#found YN directory.
		curPath+="/" if curPath[-1,1]!="/";
		ynDirs.push(curPath);
	else
		next;
	end
}
theIDHash = Hash.new();
ynDirs.each{|ynDir|
	Dir.open(ynDir).each{|curEntry|
		curPath =ynDir+curEntry;
		if curEntry=="." || curEntry==".." || File.directory?(curPath)
			next;
		end
		if curEntry[-4,4]==".pfm"
			
			id = curEntry.split(".");
			id.pop();
			id = id.join(".");
			if theIDHash[ynDir]==nil
				theIDHash[ynDir]=[];
			end
			theIDHash[ynDir].push(id);
		end
	}
}


theIDHash.keys.each{|ynDP|
	print("Doing "+ynDP+"...\n");
	#just go in order, aligning one to the next;
	first=true;
	firstPFM = nil;
	theIDHash[ynDP].each{|id|
		curPFM = loadPFMFromFile(ynDP+id+".pfm", true, false);#row headers
		#curPFM = loadPFMFromFile(ynDP+id+".pfm", false, false);#no row headers
		if first
			first=false;
			firstPFM = curPFM;
			alignedPFM=curPFM; #because no alignment
		else
			curRCPFM = curPFM.revcomp();
			distance1, offset1 = firstPFM.alignWith(curPFM);
			distance2, offset2 = firstPFM.alignWith(curRCPFM);
			
			if distance1>distance2
				alignedPFM = curRCPFM;
			else
				alignedPFM = curPFM;
			end
		end
		FileUtils.mkdir_p(outDP+ynDP);
		logoFormatPFMFile = File.open(outDP+ynDP+id+".pfm","w");
		logoFormatPFMFile.print(alignedPFM.to_s(true, false));#row headers
		#logoFormatPFMFile.print(alignedPFM.to_s(false, false));#no row headers
		logoFormatPFMFile.close();
	}
	#now have all the best alignments, 
	#need to pick an order and print RC pfms where needed
	#for now, any order; just need scale and RC/not
		#make logo
}

