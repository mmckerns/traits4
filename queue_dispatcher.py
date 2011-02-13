from weakref import ref, WeakKeyDictionary
from notifiers import Dispatcher

class QueueDispatcher(Dispatcher):
    """ This is a dispatcher which instead of notifying immediately,
    calls notifiers with changes in the order in which they occur.
    
    This is essentially 'breadth-first' dispatching.
    
    Some consequences of this:
      - each trait's set of notifiers runs to completion before any other trait
        is run
      - there is no guarantee that new is equal to the current value of the
        trait (something else may have changed the value before the current
        listener gets to run)
    """

    def __init__(self):
        import collections
        self.notifiers = WeakKeyDictionary()
        self.queue = collections.deque()

    def __call__(self, trait, obj, name, old, new):
        if old == new:
            return
        # add our stuff to the end of the queue
        self.queue.append((trait, obj, name, old, new))
        
        # if we're not the first caller, return immediately
        if len(self.queue) > 1:
            return
        
        # now process the queue until done
        while self.queue:
            trait, obj, name, old, new = self.queue[0]
            all_notifiers = self.notifiers
            if trait in all_notifiers:
                inner = all_notifiers[trait]
                if obj in inner:
                    notifiers = inner[obj]
                    dead_notifiers = []
                    for notifier in notifiers:
                        if not notifier(obj=obj, name=name, old=old, new=new):
                            dead_notifiers.append(notifier)
                    if dead_notifiers:
                        for notifier in dead_notifiers:
                            notifiers.remove(notifier)
                        if not notifiers:
                            del inner[obj]
                            if not inner:
                                del all_notifiers[trait]
            self.queue.popleft()

_queue_dispatcher = QueueDispatcher()