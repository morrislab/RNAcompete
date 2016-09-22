def revcomp(sequence)
	return sequence.reverse.tr("ATGCMRWSYKVHDB", "TACGKYSWRMBDHV"); #added for bad genomes 20110128
end

def translate(seq, codon2aa)
	translated="";
	0.upto((seq.length/3)-1){|i|
		if codon2aa[seq[i*3,3]]==nil
			translated+="?";
		else
			translated+=codon2aa[seq[i*3,3]];
		end
	}
	return translated;
end

class ChrSeq
	def initialize(mapFile)
		@fileHash = Hash.new();
		@seqHash = Hash.new();
		File.foreach(mapFile){|line|
			line.chomp!();
			if line==nil || line==""
				next;
			end
			key, fp = line.split("\t");
			@fileHash[key]=fp;
		}
	end
	def hasKey(key)
		if @fileHash[key]==nil;
			return false;
		end
		return true;
	end
	def keys()
		return @fileHash.keys();
	end
	def loadKey(key)
		@seqHash[key] = loadSequence(@fileHash[key]);
	end
	def [](key)
		if @seqHash[key]==nil
			if @fileHash[key]==nil
				raise("Unknown key for mapping: "+key+"\n");
			end
			loadKey(key);
		end
		return @seqHash[key];
	end
	def []=(key, vals)
		@seqHash[key]=vals;
	end
end

class ChrVals <ChrSeq
	def loadKey(key)
		@seqHash[key] = loadValues(@fileHash[key]);
	end
end
def loadValues(path)
	sequence=[];
	File.foreach(path){|line|
		if line[0,1]==">"
			next;
		end
		sequence.push(line.chomp().to_f());
	}
	return sequence;
end
class ChrWig <ChrSeq
	def initialize(file)
		@fileHash = Hash.new();
		@seqHash = Hash.new();
		chr=nil;
		varFixed=nil;
		i=nil;
		File.foreach(file){|line|
			line.chomp!();
			if line==nil || line==""
				next;
			end
			if line[0,19]=="track type=wiggle_0"
				next;
			end
			if line[0,9]=="fixedStep"
				varFixed="F";
				if line=~/chrom=([^ ]*)/
					chr = $1;
					chr = "chr"+chr if chr[0,3]!="chr";
				else
					raise("no chrom found");
				end
				if line=~/start=([^ ]*)/
					i=$1.to_i();
				else
					i=1;
				end
				next;
			elsif line[0,12]=="variableStep"
				if line=~/chrom=([^ ]*)/
					chr = $1;
					chr = "chr"+chr if chr[0,3]!="chr";
				else
					raise("no chrom found");
				end
				varFixed="V";
				next;
			end
			if chr==nil
				raise("No chromosome name reached yet at line: "+line+"\n");
			end
			if varFixed=="V"
				i, val = line.split("\s");
				i=i.to_i();
			else
				val = line;
			end

			val = val.to_f();
			@fileHash[chr]=chr;
			if @seqHash[chr]==nil
				@seqHash[chr] =[];
			end
			@seqHash[chr][i-1]=val;
			i+=1;
		}
	end
	def [](key)
		if @seqHash[key]==nil
			if @fileHash[key]==nil
				return nil;
			end
			loadKey(key);
		end
		return @seqHash[key];
	end
end




def loadSequence(path)
	sequence="";
	File.foreach(path){|line|
		if line[0,1]==">"||line[0,11]=="track type=" || line[0,9]=="fixedStep"
			next;
		end
		sequence = sequence+line.chomp();
	}
	return sequence;
end

def countMotif(seq, motif)
	count=0;
	0.upto(seq.length-motif.length){|i|
		if seq[i,motif.length]==motif
			count+=1;
		end
	}
	return count;
end

def printAlignment(query, reference)
	score, startPos, endPos = globalAlignment(query, reference);
	print("Score: "+score.to_s+"\n");
	i = startPos;
	qGaps=""
	rGaps=""
	while i<0
		rGaps+=" ";
		i+=1
	end
	1.upto(startPos){|j|
		qGaps+=" ";
	}
	qExtend="";
	query.length.upto(endPos-startPos){|j|
		qExtend+="%";
	}
	print (rGaps+reference+"\n"+qGaps+query+qExtend+"\n\n");
end


def globalAlignment(query, reference)
	match=1
	mismatch=-1
	gap=-1
	startPoss=[[]];
	0.upto(reference.length){|j|
		startPoss[0].push(j);
	}
	scores =[[0]*(reference.length+1)]
	1.upto(query.length){|i|
		scores.push([-i]);
		startPoss.push([-i]);
		1.upto(reference.length){|j|
			mmScore =mismatch;
			if reference[j-1]==query[i-1]
				mmScore=match;
			end
			scores[i][j]=[scores[i-1][j-1]+mmScore, scores[i-1][j]+gap, scores[i][j-1]+gap].max();
			if scores[i][j]==scores[i-1][j-1]+mmScore
				startPoss[i][j]=startPoss[i-1][j-1];
			elsif scores[i][j]==scores[i-1][j]+gap
				startPoss[i][j]=startPoss[i-1][j];
			elsif scores[i][j]==scores[i][j-1]+gap
				startPoss[i][j]=startPoss[i][j-1];
			else 
				raise("SHITAKE!\n");
			end
		}
	}
	maxValue=0;
	maxStartPos=-1;
	maxEndPos=-1;
	1.upto(reference.length){|j|
		if scores[query.length][j]>=maxValue
			maxValue=scores[query.length][j];
			maxEndPos=j;
			maxStartPos=startPoss[query.length][j];
		end
	}
	return [maxValue, maxStartPos, maxEndPos];
	
end

def swap(a,b)
	return [b,a];
end

def localScan(primer1, primer2, gStart, gEnd, gSeq)
	ignoreFlag=0;
	p1=primer1;
	p2=primer2;
	rc1 = revcomp(p1);
	rc2=revcomp(p2);
	len1=p1.length;
	len2=p2.length;
	
	if gEnd<=gStart
		temp=gStart;
		gStart=gEnd;
		gEnd=temp;
	end
	trueEnd=-1;
	trueStart=-1;
	whichEnd = 0;
	ehichStart=0;
	
	difference=0;
	i=0
	while (trueEnd==-1||trueStart==-1)&&(i<30000)
		if trueStart==-1
			if gStart-i>=0
				curStartMinus1 = gSeq[gStart-i, len1];
				curStartMinus2 = gSeq[gStart-i, len2];
				if curStartMinus1==p1 && (trueEnd==-1 || whichEnd%2==0)#start=1
					trueStart=gStart-i;
					whichStart=1;
					#print("found start -"+i.to_s+"!\n");
				elsif curStartMinus2==rc2 && (trueEnd==-1 || whichEnd%2==1)#start=RC(2)
					trueStart=gStart-i;
					whichStart=4;
					#print("found start -"+i.to_s+"!\n");
				elsif curStartMinus1==rc1 && (trueEnd==-1 || whichEnd%2==0) #start=RC(1)
					trueStart=gStart-i;
					whichStart=3;
					#print("found start -"+i.to_s+"!\n");
				elsif curStartMinus2==p2 && (trueEnd==-1 || whichEnd%2==1)#start=2
					trueStart=gStart-i;
					whichStart=2;
					#print("found start -"+i.to_s+"!\n");
				end
			end
			if gStart+i<gSeq.length
				curStartPlus1 = gSeq[gStart+i, len1];
				curStartPlus2 = gSeq[gStart+i, len2];
				if curStartPlus1==p1 && (trueEnd==-1 || whichEnd%2==0)#start=1
					trueStart=gStart+i;
					whichStart=1;
					#print("found start +"+i.to_s+"!\n");
				elsif curStartPlus2==rc2 && (trueEnd==-1 || whichEnd%2==1)#start=RC(2)
					trueStart=gStart+i;
					whichStart=4;
					#print("found start +"+i.to_s+"!\n");
				elsif curStartPlus1==rc1 && (trueEnd==-1 || whichEnd%2==0) #start=RC(1)
					trueStart=gStart+i;
					whichStart=3;
					#print("found start +"+i.to_s+"!\n");
				elsif curStartPlus2==p2 && (trueEnd==-1 || whichEnd%2==1)#start=2
					trueStart=gStart+i;
					whichStart=2;
					#print("found start +"+i.to_s+"!\n");
				end
			end
		end
		if trueEnd==-1
			if gEnd-i>=0
				curEndMinus1 = gSeq[gEnd-i-len1, len1];
				curEndMinus2 = gSeq[gEnd-i-len2, len2];
				if curEndMinus2==rc2 && (trueStart==-1 || whichStart%2==1) #end=RC(2)
					trueEnd=gEnd-i;
					whichEnd=4;
					#print("found end -"+i.to_s+"!\n");
				elsif curEndMinus1==p1 && (trueStart==-1 || whichStart%2==0) #end=1
					trueEnd=gEnd-i;
					whichEnd=1;
					#print("found end -"+i.to_s+"!\n");
				elsif curEndMinus2==p2 && (trueStart==-1 || whichStart%2==1)  #end=2
					trueEnd=gEnd-i;
					whichEnd=2;
					#print("found end -"+i.to_s+"!\n");
				elsif curEndMinus1==rc1 && (trueStart==-1 || whichStart%2==0) #end=RC(1)
					trueEnd=gEnd-i;
					whichEnd=3;
					#print("found end -"+i.to_s+"!\n");
				end
			end
			if gEnd+i<gSeq.length
				curEndPlus1 = gSeq[gEnd+i-len1, len1];
				curEndPlus2 = gSeq[gEnd+i-len2, len2];
				if curEndPlus2==rc2 && (trueStart==-1 || whichStart%2==1) #end=RC(2)
					trueEnd=gEnd+i;
					whichEnd=4;
					#print("found end +"+i.to_s+"!\n");
				elsif curEndPlus1==p1 && (trueStart==-1 || whichStart%2==0) #end=1
					trueEnd=gEnd+i;
					whichEnd=1;
					#print("found end +"+i.to_s+"!\n");
				elsif curEndPlus2==p2 && (trueStart==-1 || whichStart%2==1)  #end=2
					trueEnd=gEnd+i;
					whichEnd=2;
					#print("found end +"+i.to_s+"!\n");
				elsif curEndPlus1==rc1 && (trueStart==-1 || whichStart%2==0) #end=RC(1)
					trueEnd=gEnd+i;
					whichEnd=3;
					#print("found end +"+i.to_s+"!\n");
				end
			end
		end
		i+=1;
	end
	if trueStart==-1 &&trueEnd==-1
		raise("Could not find either start or end! "+gStart.to_s+" "+gEnd.to_s+" "+gSeq.length.to_s+"\n"+gSeq[gStart-50000, gEnd-gStart+100000]+"\n"+p1+"\t"+p2+"\n"+rc1+"\t"+rc2+"\n");
		
	end
	if trueStart==-1 #could not find proper start
		if whichEnd%2==1
			query = p2
			rcQuery=rc2
			queryLen=len2;
			whichStart=2;
		else
			query = p1;
			rcQuery=rc1;
			queryLen=len1;
			whichStart=1;
		end
		#look for imperfect match around the right distance to either side of the trueEnd
		distAway = (gEnd-gStart);
		#F/RC = forward/revComp, U/D = upstream/downstream
		score_F_U, startPos_F_U, endPos_F_U = globalAlignment(query, gSeq[trueEnd-distAway-(10*queryLen), 20*queryLen]);
		score_RC_U, startPos_RC_U, endPos_RC_U = globalAlignment(rcQuery, gSeq[trueEnd-distAway-(10*queryLen), 20*queryLen]);
		score_F_D, startPos_F_D, endPos_F_D = globalAlignment(query, gSeq[trueEnd+distAway-(10*queryLen), 20*queryLen]);
		score_RC_D, startPos_RC_D, endPos_RC_D = globalAlignment(rcQuery, gSeq[trueEnd+distAway-(10*queryLen), 20*queryLen]);
		bestHit=[score_F_U, score_RC_U, score_F_D, score_RC_D].max();
		trueStartLen =-1;
		if whichEnd>2 #check in nonRC first order
			if bestHit==score_F_U
				whichStart+=0;
				trueStart=startPos_F_U+trueEnd-distAway-(10*queryLen);
				trueStartLen = endPos_F_U-startPos_F_U;
			elsif bestHit==score_F_D
				whichStart+=0;
				trueStart=startPos_F_D+trueEnd+distAway-(10*queryLen);
				trueStartLen = endPos_F_D-startPos_F_D;
			elsif bestHit==score_RC_U
				whichStart+=2;
				trueStart=startPos_RC_U+trueEnd-distAway-(10*queryLen);
				trueStartLen = endPos_RC_U-startPos_RC_U;
			elsif bestHit==score_RC_D
				whichStart+=2;
				trueStart=startPos_RC_D+trueEnd+distAway-(10*queryLen);
				trueStartLen = endPos_RC_D-startPos_RC_D;
			end
		else #check in RC first order
			if bestHit==score_RC_U
				whichStart+=2;
				trueStart=startPos_RC_U+trueEnd-distAway-(10*queryLen);
				trueStartLen = endPos_RC_U-startPos_RC_U;
			elsif bestHit==score_RC_D
				whichStart+=2;
				trueStart=startPos_RC_D+trueEnd+distAway-(10*queryLen);
				trueStartLen = endPos_RC_D-startPos_RC_D;
			elsif bestHit==score_F_U
				whichStart+=0;
				trueStart=startPos_F_U+trueEnd-distAway-(10*queryLen);
				trueStartLen = endPos_F_U-startPos_F_U;
			elsif bestHit==score_F_D
				whichStart+=0;
				trueStart=startPos_F_D+trueEnd+distAway-(10*queryLen);
				trueStartLen = endPos_F_D-startPos_F_D;
			end
		
		end
		queryHit = query;
		if whichStart>2
			queryHit = rcQuery
		end
		
		print("Found potential start site, score=\t"+bestHit.to_s+"\t"+gSeq[trueStart, trueStartLen]+"\t"+queryHit+"\n");
		if whichStart%2==1
			if trueStart>=(trueEnd-len2) #adjust so the swapping of start and end will be right with the possible gaps in the start
				trueStart=trueStart-len1+trueStartLen;
			end
		elsif trueStart>=(trueEnd-len1) #adjust so the swapping of start and end will be right with the possible gaps in the start
			trueStart=trueStart-len2+trueStartLen;
		end
		ignoreFlag=1;
		#raise("Could not find proper start! "+gStart.to_s+" "+gEnd.to_s+" "+gSeq.length.to_s+"\n"+gSeq[gStart-100, gEnd-gStart+200]+"\n"+p1+"\t"+p2+"\n"+rc1+"\t"+rc2+"\n");
	elsif trueEnd==-1 #could not find proper end
		if whichStart%2==1
			query = p2
			rcQuery=rc2
			queryLen=len2;
			whichEnd=2;
		else
			query = p1;
			rcQuery=rc1;
			queryLen=len1;
			whichEnd=1;
		end
		#look for imperfect match around the right distance to either side of the trueStart
		distAway = (gEnd-gStart);
		#F/RC = forward/revComp, U/D = upstream/downstream
		score_F_U, startPos_F_U, endPos_F_U = globalAlignment(query, gSeq[trueStart-distAway-(10*queryLen), 20*queryLen]);
		score_RC_U, startPos_RC_U, endPos_RC_U = globalAlignment(rcQuery, gSeq[trueStart-distAway-(10*queryLen), 20*queryLen]);
		score_F_D, startPos_F_D, endPos_F_D = globalAlignment(query, gSeq[trueStart+distAway-(10*queryLen), 20*queryLen]);
		score_RC_D, startPos_RC_D, endPos_RC_D = globalAlignment(rcQuery, gSeq[trueStart+distAway-(10*queryLen), 20*queryLen]);
		bestHit=[score_F_U, score_RC_U, score_F_D, score_RC_D].max();
		trueEndLen =-1;
		if whichStart>2 #check in nonRC first order
			if bestHit==score_F_U
				whichEnd+=0;
				trueEnd=startPos_F_U+trueStart-distAway-(10*queryLen);
				trueEndLen = endPos_F_U-startPos_F_U;
			elsif bestHit==score_F_D
				whichEnd+=0;
				trueEnd=startPos_F_D+trueStart+distAway-(10*queryLen);
				trueEndLen = endPos_F_D-startPos_F_D;
			elsif bestHit==score_RC_U
				whichEnd+=2;
				trueEnd=startPos_RC_U+trueStart-distAway-(10*queryLen);
				trueEndLen = endPos_RC_U-startPos_RC_U;
			elsif bestHit==score_RC_D
				whichEnd+=2;
				trueEnd=startPos_RC_D+trueStart+distAway-(10*queryLen);
				trueEndLen = endPos_RC_D-startPos_RC_D;
			end
		else #check in RC first order
			if bestHit==score_RC_U
				whichEnd+=2;
				trueEnd=startPos_RC_U+trueStart-distAway-(10*queryLen);
				trueEndLen = endPos_RC_U-startPos_RC_U;
			elsif bestHit==score_RC_D
				whichEnd+=2;
				trueEnd=startPos_RC_D+trueStart+distAway-(10*queryLen);
				trueEndLen = endPos_RC_D-startPos_RC_D;
			elsif bestHit==score_F_U
				whichEnd+=0;
				trueEnd=startPos_F_U+trueStart-distAway-(10*queryLen);
				trueEndLen = endPos_F_U-startPos_F_U;
			elsif bestHit==score_F_D
				whichEnd+=0;
				trueEnd=startPos_F_D+trueStart+distAway-(10*queryLen);
				trueEndLen = endPos_F_D-startPos_F_D;
			end
		
		end
		queryHit = query;
		if whichEnd>2
			queryHit = rcQuery
		end
		trueEnd = trueEnd+trueEndLen;
		
		print("Found potential end site, score=\t"+bestHit.to_s+"\t"+gSeq[trueEnd-trueEndLen, trueEndLen]+"\t"+queryHit+"\n");
		if whichEnd%2==1
			if (trueStart+len2)>=trueEnd#adjust the end so that when end and start are swapped, the possible gaps in the end alignment will be included
				trueEnd=trueEnd+len1-trueEndLen;
			end
		elsif (trueStart+len1)>=trueEnd #adjust the end so that when end and start are swapped, the possible gaps in the end alignment will be included
			trueEnd=trueEnd+len2-trueEndLen;
		end
		ignoreFlag=2;
		#raise("Could not find proper end! "+gStart.to_s+" "+gEnd.to_s+" "+gSeq.length.to_s+"\n"+gSeq[gStart, gEnd-gStart]+"\n"+p1+"\t"+p2+"\n"+rc1+"\t"+rc2+"\n");
	end
	if whichStart%2==1
		addThis=len1;
	else
		addThis=len2;
	end
	if trueEnd<(trueStart+addThis)#happens when end is closer to the start than to the end
		if ignoreFlag==1
			ignoreFlag=2;
		elsif ignoreFlag==2
			ignoreFlag=1;
		end
		trueEnd, trueStart = swap(trueEnd,trueStart);
		if whichStart%2==0
			#it should
			trueStart=trueStart-len1;
			trueEnd=trueEnd+len2;
		else
			trueStart=trueStart-len2;
			trueEnd=trueEnd+len1;
			#raise("Unknown error: "+gStart.to_s+" "+gEnd.to_s+" "+trueStart.to_s+" "+trueEnd.to_s+" "+gSeq.length.to_s+"\n"+gSeq[gStart, gEnd-gStart]+"\n"+p1+"\t"+p2+"\n"+rc1+"\t"+rc2+"\n");
		end
		whichStart, whichEnd = swap(whichStart,whichEnd);
	end
	#print("Differences in GCs: "+(gStart-trueStart).to_s+"\t"+(gEnd-trueEnd).to_s+"\t"+(trueEnd-trueStart).to_s+"\t"+(gEnd-gStart).to_s+"\n");
	if whichStart%2==whichEnd%2
		raise("Both start and end use the same primer! "+gStart.to_s+" "+gEnd.to_s+" "+trueStart.to_s+" "+trueEnd.to_s+" "+gSeq.length.to_s+"\n"+gSeq[gStart, gEnd-gStart]+"\n"+p1+"\t"+p2+"\n"+rc1+"\t"+rc2+"\n");
	end
	return [trueStart, trueEnd, whichStart, whichEnd, ignoreFlag];
end

class GeneMap
	def initialize(path)
		@theMap = Hash.new()
		File.foreach(path){|line|
			line.chomp!
			yName, otherName = line.split("\t")
			yName.upcase!
			if otherName!=nil
				otherName.upcase!
				if @theMap[otherName]==nil
					@theMap[otherName]=yName;
				else
					print("Duplicate mapping of "+otherName+" to "+ @theMap[otherName]+" and "+ yName+"\n")
				end
			end
			if @theMap[yName]==nil
				@theMap[yName]=yName
			else
				print("Y-mapping duplicate: "+yName+" already mapped to "+ @theMap[yName] +"\n")
			end
		}
	end
	def getMe(thisOne)
		return @theMap[thisOne.upcase]
	end
end

def loadPFMFromFile(path, hasRowNames=true, hasHeaderLine=false)
	curPFM = PFM.new(nil)
	curPFM.load(path, hasRowNames, hasHeaderLine);
	return curPFM;
end

class PFM
	def initialize(thePFM)
		if thePFM!=nil
			last = -1;
			thePFM.keys.each{|base|
				if last==-1
					last = thePFM[base].length;
				elsif last!=thePFM[base].length
					raise("Not all bases have same number of positions! "+thePFM[base].length.to_s+", "+last.to_s+"\n");
				end
			}
			if thePFM.keys.length!=4
				raise("Not 4 bases in hash! "+thePFM.keys.join(", "));
			end
		end
		@myPWM=thePFM;
	end
	def load(path, hasRowNames=true, hasHeaderLine=false)
		@myPWM = Hash.new()
		rowNum=1;
		File.foreach(path){|line|
			line.chomp!
			if hasHeaderLine && rowNum==1
				hasHeaderLine=false
				next
			end
			thisRow = line.split("\t")
			if hasRowNames
				curLetter = thisRow.shift()
			elsif rowNum==1
				curLetter="A"
			elsif rowNum==2
				curLetter="T"
			elsif rowNum==3
				curLetter="G"
			elsif rowNum==4
				curLetter="C"
			else
				raise("bad state for PWM: "+path+"\n")
			end
			rowNum+=1
			thisRow.map!{|a| a.to_f }
			@myPWM[curLetter]=thisRow
		}
		if rowNum!=5
			raise("Did not input enough lines for "+path+"\n")
		elsif @myPWM["A"]==nil
			raise("Base A not input for "+path+"\n")
		elsif @myPWM["T"]==nil
			raise("Base T not input for "+path+"\n")
		elsif @myPWM["G"]==nil
			raise("Base G not input for "+path+"\n")
		elsif @myPWM["C"]==nil
			raise("Base C not input for "+path+"\n")
		elsif @myPWM["A"].length!=@myPWM["T"].length|| @myPWM["A"].length!=@myPWM["G"].length || @myPWM["A"].length!=@myPWM["C"].length
			raise("Not the same numbers of positions for all of A,T,G,C for "+path+"\n")
		end
	end
	
	def loadFromIUPAC(iupacCode, iupacHash)
		thePFM = Hash.new();
		thePFM["A"] = []
		thePFM["T"] = []
		thePFM["G"] = []
		thePFM["C"] = []
		state = 0;
		distsToMerge = [];
		iupacCode.split("").each{|curCode|
			if state==0
				if (curCode=="(")
					state=1
				else
					if (iupacHash[curCode]==nil)
						raise("Unknown iupac code: "+curCode+" for "+fileName+"\n")
					end
					0.upto(iupacHash["Order"].length-1){|i|
						thePFM[iupacHash["Order"][i]].push(iupacHash[curCode][i].to_f())
					}
					last = curCode
				end
			elsif state==1
				if curCode=="/"
				elsif curCode==")"
					if distsToMerge.length<=1
						raise("Bad bracket dist: no codes to dist for: "+iupacCode+"\t"+ fileName+"\n")
					end
					combinedDistribution = [0.0]*4
					#add up separate distributions
					total=0.0
					distsToMerge.each{|subCode|
						0.upto(iupacHash["Order"].length-1){|i|
							combinedDistribution[i]+=iupacHash[subCode][i].to_f()
							total+=iupacHash[subCode][i].to_f
						}
					}
					#normalize combinedDistribution
					combinedDistribution.map!{|e| e/total}
					0.upto(iupacHash["Order"].length-1){|i|
						thePFM[iupacHash["Order"][i]].push(combinedDistribution[i].to_f())
					}
					distsToMerge=[]
					state=0
				else
					distsToMerge.push(curCode)
				end
			else
				raise("Bad state for"+fileName+"\n")
			end
		}
		@myPWM = thePFM;
	end

	def normalize()
		totals = [0.0]*self.length();
		@myPWM.keys.each{|b|
			0.upto(self.length()-1){|i|
				totals[i]+=@myPWM[b][i];
			}
		}
		@myPWM.keys.each{|b|
			0.upto(self.length()-1){|i|
				@myPWM[b][i]=@myPWM[b][i]/totals[i];;
			}
		}
	end
	def alignWith(otherPFM)
		freqBG = Hash.new();
		freqBG["A"]=0.31;
		freqBG["T"]=freqBG["A"];
		freqBG["G"]=(1.0-(2.0*freqBG["A"]))/2.0;
		freqBG["C"]=freqBG["G"];
		lenMe = self.length();
		lenOther = otherPFM.length();
		bestDist=1000000
		bestOffset=0;
		(-(lenOther-1)).upto(lenMe-1){|offset|
			curDist=self.euclidDist(otherPFM,offset,freqBG);
			if curDist<bestDist
				bestDist=curDist;
				bestOffset=offset;
			end
		}
		return [bestDist, bestOffset];
	end

	def euclidDist(otherPFM, offset, freqBG)
		#take background freq into account
		#offset is for otherPFM
		#if offset<0
		iMe = 0
		iOther = 0;
		position=offset;
		distance = 0.0;
		onlyOne = 0;
		#iOther is hanging off the left side
		while position<0 # removed the following clause because this should never happen-> && iOther<otherPFM.length()
			#p("iOther on left");
			#align BG to otherPFMa
			temp = 0.0;
			["A", "T", "G", "C"].each{|curBase|
				temp+=(otherPFM.myPWM[curBase][iOther]-freqBG[curBase])**2;
			}
			distance+=Math.sqrt(temp);
			#p(distance);
			position+=1;
			iOther+=1;
			onlyOne=1;
		end
		#case where iM is hanging off the left side
		while position>iMe
			#p("iMe on left");
			#align BG to otherPFMa
			temp = 0.0;
			["A", "T", "G", "C"].each{|curBase|
				temp+=(@myPWM[curBase][iMe]-freqBG[curBase])**2;
			}
			distance+=Math.sqrt(temp);
			#p(distance);
			iMe+=1;
			onlyOne=onlyOne|2;
		end
		if onlyOne==3
			raise("More bad shit here");
		end
		#main alignment
		while iOther<otherPFM.length() && iMe<self.length()
			temp = 0.0;
			["A", "T", "G", "C"].each{|curBase|
				temp+=(otherPFM.myPWM[curBase][iOther]-@myPWM[curBase][iMe])**2;
			}
			distance+=Math.sqrt(temp);
			#p(distance);
			iOther+=1;
			iMe+=1;
		end
		#right side (try each, though only one should ever happen)
		onlyOne=0;
		while iOther<otherPFM.length()
			#p("iOther on right");
			temp = 0.0;
			["A", "T", "G", "C"].each{|curBase|
				temp+=(otherPFM.myPWM[curBase][iOther]-freqBG[curBase])**2;
			}
			distance+=Math.sqrt(temp);
			#p(distance);
			onlyOne=1;
			iOther+=1;
		end
		while iMe<self.length()
			#p("iMe on right");
			temp = 0.0;
			["A", "T", "G", "C"].each{|curBase|
				temp+=(@myPWM[curBase][iMe]-freqBG[curBase])**2;
			}
			distance+=Math.sqrt(temp);
			#p(distance);
			onlyOne=onlyOne|2;
			iMe+=1;
		end
		if onlyOne==3
			raise("Bad shit going down, right here.");
		end
		return distance;
	end
	def revcomp()
		rcPWM = Hash.new();
		rcPWM["A"]=@myPWM["T"].reverse();
		rcPWM["T"]=@myPWM["A"].reverse();
		rcPWM["G"]=@myPWM["C"].reverse();
		rcPWM["C"]=@myPWM["G"].reverse();
		return PFM.new(rcPWM);
	end

	def length()
		return @myPWM["A"].length
	end
	def to_IUPAC(iupacFP)
		require 'HASHFILE.rb'
		iupacHash = loadHashFile(iupacFP);
		baseOrder = iupacHash["Order"];
		
		iupacBaseIndeces = Hash.new();
		temp=0;
		newPFM = Hash.new();
		baseOrder.each{|base|
			iupacBaseIndeces[base]=temp;
			newPFM[base]=[];
			temp+=1;
		}
		iupacString = "";
		totalDist = 0;
		0.upto(self.length()-1){|i|
			minDist = 100000;
			minLetter = "";
			curPFMRow = [];
			iupacHash.keys.each{|iupacLetter|
				if iupacLetter=="Order"
					next;
				end
				curDist = 0;
				baseOrder.each{|base|
					curDist += (@myPWM[base][i]-iupacHash[iupacLetter][iupacBaseIndeces[base]].to_f())**2;
				}
				curDist=Math.sqrt(curDist);
				if curDist<minDist
					minLetter=iupacLetter;
					minDist=curDist;
					curPFMRow = iupacHash[iupacLetter];
				end
			}
			temp=0;
			baseOrder.each{|base|
				newPFM[base].push(curPFMRow[temp].map(){|a| a.to_f});
				temp+=1;
			}
			iupacString+=minLetter;
			totalDist+=minDist;
		}
		#drop Ns/Xs at the beginning
		while (iupacString[0,1].upcase()=="N" || iupacString[0,1].upcase()=="X")
			["A","T","G","C"].each{|base|
				newPFM[base].shift();
			}
			iupacString =iupacString[1,iupacString.length-1];
		end
		#drop Ns/Xs at the end
		while (iupacString[-1,1].upcase()=="N" || iupacString[-1,1].upcase()=="X")
			["A","T","G","C"].each{|base|
				newPFM[base].pop();
			}
			iupacString =iupacString[0,iupacString.length-1];
		end
		return [PFM.new(newPFM), iupacString, totalDist];
	end
	
	def scan(sequence)
		fScores= [];
		rScores= [];
		bestScores= [];
		thePWM = self.toPWM();
		revPWM = self.revcomp().toPWM();
		0.upto(sequence.length()-self.length()){|i|
			curScore = 0;
			0.upto(self.length-1){|j|
				curScore+=thePWM[sequence[i+j,1]][j];
			}
			revScore =0;
			0.upto(self.length-1){|j|
				revScore+=revPWM[sequence[i+j,1]][j];
			}
			fScores.push(curScore);
			rScores.push(revScore);
			bestScores.push([curScore, revScore].max());
		}
		return [fScores, rScores, bestScores];
	end
	def toPWM(bgFs = {"A"=>0.31, "T"=>0.31, "G"=>0.19, "C"=>0.19})
		newPWM = Hash.new();
		["A","T","C","G"].each{|base|
			newPWM[base]=[];
			@myPWM[base].each{|freq|
				if freq==0
					newPWM[base].push(-800);
				else
					newPWM[base].push((Math.log(freq/bgFs[base])/Math.log(2)));
				end
			}
		}
		return newPWM;
	end

	def to_s(hasRowNames=false, hasHeaderLine=false)
		returnMe=""
		if hasHeaderLine
			returnMe+="PO"
			0.upto(@myPWM["A"].length-1){|i|
				returnMe+="\t"+i.to_s
			}
			returnMe+="\n"
		end
		["A", "T", "G", "C"].each{|curBase|
			if hasRowNames
				returnMe+=curBase+"\t"
			end
			tempArray = @myPWM[curBase].map{|a| a.to_s}
			returnMe+=tempArray.join("\t")+"\n"
		}
		return returnMe
	end
	
	def to_MEME()
		returnMe=""
		0.upto(@myPWM["A"].length-1){|i|
			["A", "C", "G", "T"].each{|curBase|
				returnMe+=@myPWM[curBase][i].to_s+"\t"
			}
			returnMe=returnMe[0, returnMe.length-1]+"\n";
		}
		return returnMe
	end

	attr_accessor :myPWM
end

def trimAlignment(alignment, cutoff=0.1, background={"A"=>0.25, "T"=>0.25, "G"=>0.25, "C"=>0.25})
	pfm = makePFMFromAlignment(alignment, pseudocount=0.5);
	require "RINTERFACE.rb";
	#from front
	directions = [[],[]];
	0.upto(pfm.length()-1){|i|
		directions[0].push(i);
		directions[1].push(pfm.length()-1-i);
	}
	trim=[0,0];
	scores = [];
	maxScore = 0;
	0.upto(pfm.length()-1){|i|
		counts = [];
		pfmProbs = [];
		backgroundProbs = [];
		background.keys.each{|base|
			counts.push(pfm.myPWM[base][i]*alignment.length());
			backgroundProbs.push(background[base]);
			pfmProbs.push(pfm.myPWM[base][i]);
		}	
		bgP = callRFunction("dmultinom", {"x"=>counts, "prob"=>backgroundProbs,"log"=>"TRUE"});
		pfmP = callRFunction("dmultinom", {"x"=>counts, "prob"=>pfmProbs,"log"=>"TRUE"});
		bgP = bgP[0][0].to_f();
		pfmP = pfmP[0][0].to_f();
		p(["Trim: ",i, bgP, pfmP, pfmP-bgP]);
		scores.push(pfmP-bgP);
	}
	maxScore = scores.max();
	0.upto(directions.length()-1){|j|
		d=directions[j];
		d.each{|i|
			if scores[i]<(cutoff*maxScore)
				trim[j]+=1;
			else
				break;
			end
		}
	}
	#trin[0] is from the front, trim[1] is from the back
	newAlignment = [];
	alignment.each{|seq|
		newAlignment.push(seq[trim[0], seq.length()-trim[0]-trim[1]]);
	}
	return newAlignment;
end

def makePFMFromAlignment(alignment, pseudocount=0.5)
	curPFM = {"A"=>[], "T"=>[], "C"=>[], "G"=>[]};
	0.upto(alignment[1].length()-1){|i|
		["A","T","G","C"].each{|base|
		curPFM[base][i]=pseudocount; #pseudocount
		}
	}
	alignment.each{|seq|
		0.upto(seq.length()-1){|i|
			curPFM[seq[i,1]][i]+=1;
		}
	}
	curPFM = PFM.new(curPFM);
	curPFM.normalize();
	return curPFM;
end


def makePFMsFromAlignment(alignment, cutoff=10, pseudocount=0.5)
	
	thePFM = makePFMFromAlignment(alignment, pseudocount);
	#print("BEFORE: \n"+thePFM.to_s());
	pfms = [thePFM];
	#go through all sets two-mers and see if distribution is roughly equal to what would be expected by the PFM
	dinucs = [];
	["A","T","G","C"].each(){|b1|
		["A","T","G","C"].each(){|b2|
			dinucs.push(b1+b2);
		}
	}
	0.upto(alignment[0].length()-2){|i|
		counts = Hash.new();
		dinucs.each{|diN|
			counts[diN]=0.0;
		}
		dinucPs = [];
		alignment.each{|seq|
			counts[seq[i,2]]+=1;
		}
		countArray=[];
		dinucs.each{|diN|
			dinucPs.push(counts[diN]/alignment.length());
			countArray.push(counts[diN]);
		}

		0.upto(pfms.length()-1){|j|
			#two mers starting at i
			curPFM = pfms[j];
			pfmPs = [];
			dinucs.each(){|diN|
				pfmPs.push(curPFM.myPWM[diN[0,1]][i]*curPFM.myPWM[diN[1,1]][i+1]);
			}
			#compare observed/expected dinucleotide distribution
			diP = callRFunction("dmultinom", {"x"=>countArray, "prob"=>dinucPs,"log"=>"TRUE"});
			diP = diP[0][0].to_f();
			pfmP = callRFunction("dmultinom", {"x"=>countArray, "prob"=>pfmPs,"log"=>"TRUE"});
			pfmP = pfmP[0][0].to_f();
			p([i, diP, pfmP, diP-pfmP]);
			if diP-pfmP>cutoff
				#split this PFM up into two somehow
			else
				break;
			end

		}
	}
	#print("AFTER:\n"+pfms[0].to_s());
	return pfms;
end


def expandIUPAC(motif)
	length = motif.length;
	expandedMotifs = [motif];
	expansionHash = Hash.new();
	expansionHash["M"]=["A","C"];
	expansionHash["R"]=["A","G"];
	expansionHash["W"]=["A","T"];
	expansionHash["S"]=["C","G"];
	expansionHash["Y"]=["C","T"];
	expansionHash["K"]=["G","T"];
	expansionHash["V"]=["A","C", "G"];
	expansionHash["H"]=["A","C", "T"];
	expansionHash["D"]=["A","G", "T"];
	expansionHash["B"]=["C","G", "T"];
	expansionHash["X"]=["A","T", "G", "C"];
	expansionHash["N"]=["A","T", "G", "C"];
	0.upto(length-1){|i|
		curLetter = motif[i,1];
		if expansionHash[curLetter]!=nil
			expandBy = expansionHash[curLetter].length;
			lastLength =expandedMotifs.length();
			0.upto(expandBy-1){|j|
				0.upto(lastLength-1){|k|
					expandedMotifs[k+(lastLength*j)]=(expandedMotifs[k][0,i]+expansionHash[curLetter][j]+expandedMotifs[k][i+1,length-(i+1)]);
				}
			}
		end
	}
	return expandedMotifs;
end
		



