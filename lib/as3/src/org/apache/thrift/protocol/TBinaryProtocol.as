/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements. See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership. The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License. You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.apache.thrift.protocol {

  import flash.utils.ByteArray;
  
  import com.hurlant.math.BigInteger;
  import org.apache.thrift.TError;
  import org.apache.thrift.transport.THttpClient;
  import org.apache.thrift.transport.TTransport;
    
  /**
   * Binary protocol implementation for thrift.
   */
  public class TBinaryProtocol implements TProtocol {

    private static var ANONYMOUS_STRUCT:TStruct = new TStruct();

    protected static const VERSION_MASK:int = int(0xffff0000);
    protected static const VERSION_1:int = int(0x80010000);

    protected var strictRead_:Boolean = false;
    protected var strictWrite_:Boolean = true;
    
    protected var readLength_:int;
    protected var checkReadLength_:Boolean = false;

  /**
   * Factory
   */
   /*
  public static class Factory implements TProtocolFactory {
    protected boolean strictRead_ = false;
    protected boolean strictWrite_ = true;

    public Factory() {
      this(false, true);
    }

    public Factory(boolean strictRead, boolean strictWrite) {
      strictRead_ = strictRead;
      strictWrite_ = strictWrite;
    }

    public TProtocol getProtocol(TTransport trans) {
      return new TBinaryProtocol(trans, strictRead_, strictWrite_);
    }
  }
  */
  
    private var trans_:TTransport;
    
    /**
     * Constructor
     */
    public function TBinaryProtocol(trans:TTransport, strictRead:Boolean=false, strictWrite:Boolean=true) {
      trans_ = trans;
      strictRead_ = strictRead;
      strictWrite_ = strictWrite;
    }
  
    public function getTransport():TTransport {
      return trans_;
    }
    
    public function writeMessageBegin(message:TMessage):void {
        if (strictWrite_) {
          var version:int = VERSION_1 | message.type;
          writeI32(version);
          writeString(message.name);
          writeI32(message.seqid);
        } else {
          writeString(message.name);
          writeByte(message.type);
          writeI32(message.seqid);
        }
    }
    
      public function writeMessageEnd():void {}
  
    public function writeStructBegin(struct:TStruct):void {}
  
    public function writeStructEnd():void {}
  
    public function writeFieldBegin(field:TField):void {
      writeByte(field.type);
      writeI16(field.id);
    }
    
    public function writeFieldEnd():void {}
    
    public function writeFieldStop():void {
      writeByte(TType.STOP);
    }
    
    public function writeMapBegin(map:TMap):void {
      writeByte(map.keyType);
      writeByte(map.valueType);
      writeI32(map.size);
    }
    
    public function writeMapEnd():void {}
    
    public function writeListBegin(list:TList):void {
        writeByte(list.elemType);
        writeI32(list.size);
    }
    
    public function writeListEnd():void {}
    
    public function writeSetBegin(set:TSet):void {
        writeByte(set.elemType);
        writeI32(set.size);
      }
      
      public function writeSetEnd():void {}
      
      public function writeBool(b:Boolean):void {
        writeByte(b ? 1 : 0);
      }
      
      private var out:ByteArray = new ByteArray();
      public function writeByte(b:int):void {
        reset(out);
        out.writeByte(b);
        trans_.write(out, 0, 1);
      }
      
      public function writeI16(i16:int):void {
        reset(out);
        out.writeShort(i16);
        trans_.write(out, 0, 2);
      }
      
      public function writeI32(i32:int):void {
        reset(out);
        out.writeInt(i32);
        trans_.write(out, 0, 4);
      }
      
      public function writeI64(i64:BigInteger):void {
        reset(out);
        var ba:ByteArray = i64.toByteArray();
        ba.position = 0;

        // pad the output to make sure this 64-bit number takes 
        // all 64-bits, and no more since BigInteger can handle more
        var difference:int = 8 - Math.min(8, ba.length);
        for( ; difference > 0; difference-- ){
          out.writeByte(0);
        }
        out.writeBytes(ba, 0, Math.min(8, ba.bytesAvailable));
        trans_.write(out, 0, 8);
      }
      
      public function writeDouble(dub:Number):void {
        reset(out);
        out.writeDouble(dub);
        trans_.write(out, 0, 8);
      }
      
      private var stringOut:ByteArray = new ByteArray();
      
      public function writeString(str:String):void {
        reset(stringOut);
        stringOut.writeUTFBytes(str);
        
        writeI32(stringOut.length);
        trans_.write(stringOut, 0, stringOut.length);
      }
  
    public function writeBinary(bin:ByteArray):void {
      writeI32(bin.length);
      trans_.write(bin, 0, bin.length);
    }
  
    /**
     * Reading methods.
     */
  
    public function readMessageBegin():TMessage {
      var size:int = readI32();
      if (size < 0) {
        var version:int = size & VERSION_MASK;
        if (version != VERSION_1) {
          throw new TProtocolError(TProtocolError.BAD_VERSION, "Bad version in readMessageBegin");
        }
        return new TMessage(readString(), size & 0x000000ff, readI32());
      }
      else {
        if (strictRead_) {
          throw new TProtocolError(TProtocolError.BAD_VERSION, "Missing version in readMessageBegin, old client?");
        }
            return new TMessage(readStringBody(size), readByte(), readI32());
          }
    }
  
    public function readMessageEnd():void {}
  
    public function readStructBegin():TStruct {
        return ANONYMOUS_STRUCT;
      }
  
    public function readStructEnd():void {}
  
    public function readFieldBegin():TField {
        var type:int = readByte();
        var id:int = type == TType.STOP ? 0 : readI16();
        return new TField("", type, id);
    }
  
    public function readFieldEnd():void {}
  
    public function readMapBegin():TMap {
        return new TMap(readByte(), readByte(), readI32());
    }
  
    public function readMapEnd():void {}
  
    public function readListBegin():TList {
        return new TList(readByte(), readI32());
    }
  
    public function readListEnd():void {}
  
    public function readSetBegin():TSet {
      return new TSet(readByte(), readI32());
    }
  
    public function readSetEnd():void {}
  
    public function readBool():Boolean {
        return (readByte() == 1);
    }
  
    private var bytes:ByteArray = new ByteArray();
    
    public function readByte():int {
      readAll(1);
        return bytes.readByte();
      }
  
    public function readI16():int {
        readAll(2);
        return bytes.readShort();
    }
  
    public function readI32():int {
      readAll(4);
      return bytes.readInt();
    }
  
    public function readI64():BigInteger {
      readAll(8);
      return new BigInteger(bytes);
    }
  
    public function readDouble():Number {
      readAll(8);
      return bytes.readDouble();
    }
  
    public function readString():String {
      var size:int = readI32();
        readAll(size);
        return bytes.readUTFBytes(size);
      }
  
    public function readStringBody(size:int):String {
        readAll(size);
        return bytes.readUTFBytes(size);
      }
  
    public function readBinary():ByteArray {
        var size:int = readI32();
        checkReadLength(size);
        var buf:ByteArray = new ByteArray();
        trans_.readAll(buf, 0, size);
        return buf;
    }
  
    private function readAll(len:int):void {
      reset(bytes);
      
      checkReadLength(len);
        trans_.readAll(bytes, 0, len);
        
        bytes.position = 0;
      }
  
    public function setReadLength(readLength:int):void {
      readLength_ = readLength;
      checkReadLength_ = true;
    }
  
    protected function checkReadLength(length:int):void {
        if (checkReadLength_) {
            readLength_ -= length;
            if (readLength_ < 0) {
              throw new TError("Message length exceeded: " + length);
            }
        }
      }
    
    private static function reset(arr:ByteArray):void {
      arr.length = 0;
      arr.position = 0;
    }
  }
}
