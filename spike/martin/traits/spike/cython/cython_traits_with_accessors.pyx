from meta_has_traits import MetaHasTraits


VERSION = 'Cython with Accessors'


class HasTraits(object):
    """ The base class for all classes that have traits! """

    __metaclass__ = MetaHasTraits


class TraitError(Exception):
    pass


cdef class TraitAccessor:

    # The name of the attribbute that the trait is 'bound' to. This is
    # set during class instantiation time due to the poor design of the
    # descriptor protocol.
    cdef public bytes name

    # The associated trait type.
    cdef public object trait_type

    def __init__(self, name, trait_type):
        self.name = name
        self.trait_type = trait_type
        return
    
    #### 'Descriptor' protocol ################################################

    def __get__(self, obj, cls):
        """ Get the value of the descriptor. """

        return obj.__dict__[self.name]
    
    def __set__(self, obj, value):
        """ Set the value of the descriptor. """

        actual_value = self.trait_type.validate(value)

        obj.__dict__[self.name] = actual_value

        return


# A callable to wrap trait types.
trait_type_wrapper = TraitAccessor


cdef class TraitType:
    #### 'TraitType' protocol #################################################

    # The name of the attribbute that the trait is 'bound' to. This is
    # set during class instantiation time due to the poor design of the
    # descriptor protocol.
    cdef public bytes name

    cpdef validate(TraitType self, object value):
        """ Validate the given value.

        Raise a TraitError if the value is not valid for this type.

        """
        
        raise NotImplemented


cdef class Int(TraitType):
    #### 'TraitType' protocol #################################################

    cpdef inline validate(Int self, object value):
        if not type(value) is int:
            raise TraitError

        return value

#### EOF ######################################################################
