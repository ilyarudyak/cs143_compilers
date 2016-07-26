class List inherits A2I {

  item:Object;
  next:List;

  init(i:Object, n:List):List {
    {
      item <- i;
      next <- n;
      self;
    }
  }; -- end of init()

  flatten():String {
    let string:String <- 
      case item of
        i:Int => i2a(i);
        s:String => s;
        o:Object => { abort(); ""; };
      esac
    in
      if (isvoid next) then
        string
      else
        string.concat(next.flatten())
      fi
  }; -- end of flatten()

}; -- end of class List

class Main inherits IO {

  main():Object {

    let hello:String      <- " Hello ",
        my_friend:String  <- " my friend!\n",
        nil:List,
        list:List <-
              (new List).init( 42, 
                (new List).init( hello,
                (new List).init( my_friend, nil ) ) ) 
    in
        out_string( list.flatten() )

  }; -- end of main

}; -- end of class





















